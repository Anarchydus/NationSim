globals [
year
csv_list
]

breed[ economies economy]

breed[ governments government]

breed[private_sectors private_sector]

breed[public_sectors public_sector]

breed[markets market]

economies-own [
  ;;How many uneducated people work in this economy [Current][Max]]
  workplaces
  ;;How much money a job makes
  salaries

  ;;How much money this economy produces anually, list
  profits
  ;;What the Economy produces
  resources
  ;;How much the economy produced last
  output

  ;;The type of Economy
  etype
  ;;Action taking
  ;;Current state of Sector
  econ_state
  ;;List of possible states
  econ_states
  ;;List of possible actions
  econ_actions
]

private_sectors-own[
  ;;Which economies are being handled by this sector
  econs
  ;;how much money the sector makes anually, list
  profits
]

public_sectors-own[
  ;;Which economies are being handled by this sector
  econs
  ;;How much money the sector makes in total after taxes, list
  profits

  ;;Where funds go in their economies
  funding_distribution

  ;;Action taking
  ;;Current state of Sector
  sec_state
  ;;List of possible states
  sec_states
  ;;List of possible actions
  sec_actions
]


governments-own[
  ;;How much of the salary of a worker is taken by the government
  taxes

  ;;How well liked the current government is
  approval

  ;;The combined value of everything that was produced, aka the net income of the state
  gdp

  ;;Collected tax money
  public_funding

  ;;Public funding percentage [Public_sector][Education]
  budget

  ;;How many workers do not have a job
  unemployment

  ;;Populations over time
  population

  ;;Sectors
  pr_sector

  pu_sector

  ;;Markets
  internal_market

  ;;Action taking
  ;;Current state of Government
  gov_state
  ;;List of possible states
  gov_states
  ;;List of actions
  gov_actions

]

markets-own[

  ;;How much of a given resource a market has
  ressources

  ;;How much the market pays for an individual resource
  prices

  ;;An internal market ought to be pretty stable for every good created
  market_owner
]

;;Function which runs at start of simulation and sets initial parameters
;;Creates a government for testing and sets up the csv_list which is used to make a csv file of data later down the line
to setup
  clear-all
  set year 0
  set csv_list []
  create-governments 1[
  governments.setup
  ]
  reset-ticks
end

;;Function which runs once per time step
to go
  ;;If we have not reached the end of our runtime
  if(year < runtime)
  [
    ;;Update current year and each government
    set year year + 1
    ask governments[
      governments.update
    ]
    tick
  ]
end

;;Functions related to Governments

;;Set up a single government with initial values
;;Really, this should all be changeable from the interface but that would mean even more input fields
to governments.setup
  ;;Taxes people pay as percentage
  set taxes 25.0

  ;;Approval of people of the government as percentage
  set approval 50

  ;;The total wealth of our country, recorded for each timestep
  set gdp (list initial_wealth)

  ;;The budget for funding the public sector, recorded for each timestep
  set public_funding (list floor (initial_wealth / 4))

  ;;The balance between budget for education and public funding in decimals, recorded for each timestep
  set budget (list 0.5 0.5)

  ;;List of how many unemployed citizens the nation, recorded for each timestep
  set unemployment (list floor (initial_population * (initial_unemployment / 100)))

  ;;List of the current number of citizens in the nation, recorded for each timestep
  set population (list initial_population)

  ;;Creates and records a private sector class belonging to the nation
  hatch-private_sectors 1[
    ask myself[
      set pr_sector myself
    ]
    ;;Set up a private sector using our initial population
    sectors.setup "private" item 0 [population] of myself 0
  ]

 ;;Creates and records a public sector using our initial population
 hatch-public_sectors 1 [
    ask myself[
      set pu_sector myself
    ]
    sectors.setup "public" item 0 [population] of myself floor (initial_wealth / 2)
  ]

  ;;Creates and records and internal marked for the nation
  hatch-markets 1[
    set market_owner myself
    ask myself[
      set internal_market myself
    ]
    market.setup
  ]


  ;;Set up actions the nation can take as part of it's decisionmaking
  let relax [[]->
    ;;Do nothing
  ]

  ;;Increase the budget of the public sector to stimulate growth by increasing taxation on the private sector
  ;;Also shift budget priority in favor of the public sector
  let raise_public_profits [[]->
    if item 0 budget < 1
    [
    set budget (list (min (list (item 0 budget + 0.1) 1)) (max (list (item 1 budget - 0.1) 0)))
    ]
    if taxes < 100
    [
      set taxes min (list (taxes + 2) 100)
    ]
  ]

  ;;Increase the budget of education by increasing taxation on the private sector
  ;;Also shift budget priority in favor of education
  let fund_education [[]->
    if item 1 budget < 1
    [
      set budget (list (max (list (item 0 budget - 0.1) 0)) (min (list (item 1 budget + 0.1) 1)) )
    ]
    if taxes < 100
    [
      set taxes min (list (taxes + 2) 100)
    ]
  ]

  ;;Lower the taxes of the private sector
  let lower_taxes [[] ->
    set taxes max (list (taxes - 2) 0)
  ]

  ;;In case we pic a state that does not exist
  let error_handling [[x] ->
    show (word  "An error occured. The state "  x   " does not exist")
  ]

  ;;Set up what status means what action is to be taken in a 1-1 list, and set current state of government to be appropriate
  set gov_state  "All is fine"
  set gov_states  (list "All is fine" "Low Profits Public" "Low Profits Private" "Low Education" "Low Approval")
  set gov_actions (list relax raise_public_profits lower_taxes fund_education lower_taxes error_handling)
end

;;Runs once per tick for each government
to governments.update
  ;;Find the new population of the nation
  set population lput (max (List ((last population) + floor pop_growth) 0)) population

  ;;place the workforce into new positions
  divide_workforce

  ;;Update the market
  ask internal_market [
    market.update
  ]

  ;;Update our work sectors
  ask pr_sector[
    sectors.update "private"
  ]
  ask pu_sector[
    sectors.update "public"
  ]

  ;;Update our money and approval
  governments.update_profits
  governments.update_approval

  ;;Do decisionmaking
  governments.find_state
  switch gov_state gov_states gov_actions self
end

;;Find the current state of the nation for decisionmaking
to governments.find_state

  ;;We set default state which is kept if nothing else in the function applies
  set gov_state "All is fine"

  ;;We make an array of every economy of the nation, both private and public sector
  let all_econs []

  ask pr_sector
  [
    ask econs [
      set all_econs lput self all_econs
    ]
  ]

  ask pr_sector
  [
    ask econs [
      set all_econs lput self all_econs
    ]
  ]

  ;;We find the difference in the profits between the private and the public sector
  let profit_difference abs (last [profits] of pr_sector - last [profits] of pu_sector)

  ;;If the private sectors profits where larger than those of the public sector by more than a third of the total profits of the public sector, set the state to handle low public profits
  ifelse((last [profits] of pr_sector  > last [profits] of pu_sector) and (profit_difference >= last [profits] of pu_sector / 3) and((item 0 budget < 1 ) or (taxes < 100)))
  [
    set gov_state "Low Profits Public"
  ]
  [
    ;;If instead the opposite is true, set the state to handle low private profits
    ifelse((last [profits] of pr_sector < last [profits] of pu_sector)and (profit_difference >= last [profits] of pr_sector / 3) and (taxes > 0))
    [
      set gov_state "Low Profits Private"
    ]
    [
      ;;If neither of those is true, but the education system is currently receiving less funding than the public sector
      ifelse(item 0 budget > item 1 budget and (item 1 budget < 1 or taxes < 100))
      [
        set gov_state "Low Education"
      ]
      [
        ;;If none of the other are applicable, but we have low national approval of the government
        if (approval < 50 and (taxes > 0))
        [
          set gov_state "Low Approval"
        ]
      ]
    ]
  ]

;;Finally, if none of the above is true, we remain in the default state
end

;;Updates the lists of the government class
to governments.update_profits

  ;;Sets the total money of the nation to be equal to the total profits of both sectors
  set gdp lput ( (last ([profits] of pr_sector)) + (last ([profits] of pu_sector)) + last public_funding ) gdp

end

;;Updates the approval of the people of their government
;;We want that approval to be high
to governments.update_approval
  ;;we rate approval based on unemployment and taxes vs gdp and welfare

  ;;For every percentage of the population that is unemployed, remove 1 percent of approval
  let unemployment_impact min (list (max (list (last unemployment / (last population + 1)) 0)) 50)

  ;;For every percent of taxation, remove 2 percent of approval
  let taxes_impact min (list (max ( list (taxes * 2) 0)) 50)

  ;;Total negative impact is the sum of these two
  let negative_impact unemployment_impact + taxes_impact

  ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)


  ;;Using linear interpolation we find the impact of the rise of gdp and welfare on our approval
  ;;x0y0 = gdp_percentage min, impact min
  ;;x1y1 = gdp_percentage max, impact max
  let gdp_percentage 0
  if( year < 1)
  [
    let last_gdp_dif  (item (length gdp - 2) gdp - last gdp)
    set gdp_percentage last gdp / last_gdp_dif
  ]


  let yp -50 + ((50 + 50)/(0.5 + 0.5)) * (gdp_percentage + 0.5)
  let gdp_impact min (list (max (list yp -50)) 50)

  ;;x0y0 = welfare min, impact min
  ;;x1y1 = welfare + education, impact max

  let welfare_percentage 0
  if(year < 1)
  [
    let last_welfare_dif (item (length public_funding - 2) public_funding - last public_funding)
    set welfare_percentage last public_funding / last_welfare_dif
  ]

  set yp -50 +((50 + 50)/(0.5 + 0.5)) * (welfare_percentage + 0.5)
  let welfare_impact min (list (max (list yp -50)) 50)

  let positive_impact gdp_impact + welfare_impact

   ;;We update our approval by deducting the impact of the negative from the impact of the positive.
   ;;Approval starts at 50 if neither positives nor negatives contribute, and has to stay between 100 and 0
  set approval min (list (max (list (50 + (positive_impact - negative_impact)) 0)) 100)
end

;;Sectors

;;Function which sets up a single sector based on the type of sector wanted, the population of the nation creating it, and the budget provided(if applicable)
to sectors.setup[sector_type pop i_budget]

  ;;We create three economies to simulate the production, industry, and service economies
  set econs []
  hatch-economies 3 [
    ask myself[
      set econs lput myself econs
    ]
    economies.setup (length [econs] of myself) - 1
  ]
  set econs turtle-set econs

  ;;Set the intial wealth of the sector to be equal to half the initial wealth fo the nation.
  set profits (list (initial_wealth / 2))

  ;;If we are making a public sector, we divide the funding provided evenly between the three economies
  if sector_type = "public"
  [
     set funding_distribution (list  (1 / 3) (1 / 3) (1 / 3))


    ;;We set up decision making actions for the sector to shift where the funding it receives should go
    let funding_1 [[]->
      set funding_distribution (list (min (list (item 0 funding_distribution + 0.2) 1)) (max(list (item 1 funding_distribution - 0.1) 0)) (max (list (item 2 funding_distribution - 0.1)0)) )
    ]
    let funding_2 [[]->
      set funding_distribution (list (max(list(item 0 funding_distribution - 0.1)0)) (min (list (item 1 funding_distribution + 0.2)1)) (max(list(item 2 funding_distribution - 0.1)0)) )
    ]
    let funding_3 [[]->
      set funding_distribution (list (max(list(item 0 funding_distribution - 0.1)0)) (max(list(item 1 funding_distribution - 0.1)0)) (min (list (item 2 funding_distribution + 0.2)1)) )
    ]

    ;;And set up a default state and error state
    let relax [[]-> ]
    let error_handling [[x] ->
    show (word  "An error occured. The state "  x   " does not exist")
    ]

    ;;We map the list of potential actions and the states the nation can be in 1-1
    set sec_actions (list relax funding_1 funding_2 funding_3 error_handling)
    set sec_state "All is well"
    set sec_states (List"All is well" "Econ_1_low" "Econ_2_low" "Econ_3_low")
  ]
end

;;Updates a sector of type sector_type every timestep
to sectors.update [sector_type]

  let yearly_profits 0
  let sector self

  ;;If we do not shuffle the order in which our economies get to run their update code, we create lockout for slower economies
  let random-order_econs  (list )

  ;;We fill and shuffle the list
  ask econs [
    set random-order_econs lput self random-order_econs
  ]
  set random-order_econs shuffle random-order_econs

  ;;For every economy we update it and add the profits to our yearly profits
  ;;If it is a private sector, we also deduct taxation from our profits
  foreach random-order_econs [ econ ->
    ask econ[

      economies.update

      let econ_profits  last profits
      set yearly_profits yearly_profits + econ_profits
    ]
  ]

  ;;Update profits for this timestep
  set profits lput yearly_profits profits

  ;;If the sector is public, we fund the economies as appropriate
  if(sector_type = "public")
  [
    let owner one-of governments with [pu_sector = sector]

    let public_funds 0

    ask owner
    [
      set public_funds last public_funding * item 0 budget
    ]

    let i 0
    while [i < 3]
    [
      ask (item i ([self] of econs))[
        set profits replace-item (length profits - 1) profits (last profits + (public_funds * item i [funding_distribution] of myself))
      ]
      set i i + 1
    ]

    ;;We then find the current state of the sector and run our actions accordingly
    sectors.find_state sector_type
    switch sec_state sec_states sec_actions self
  ]
end

;;Finds the current state of our sector
to sectors.find_state [sector_type]
  ;; "Econ_1_low" "Econ_2_low" "Econ_3_low"

  ;;Make a list of the incomes of all three economies of the sector
  let incomes []
  ask econs [
    set incomes lput last profits incomes
  ]

  ;;Find the difference between the highest and the lowest
  let difference (max incomes - min incomes)

  ;;Check if that difference is more than a third of the lowest income
  ifelse(difference > (min incomes / 3))
  [
    ;;If so, set the appropriate economy to low
    ifelse( min incomes = item 0 incomes)
    [
      set sec_state "Econ_1_low"

    ]
    [
      ifelse (min incomes = item 1 incomes)
      [
        set sec_state "Econ_2_low"
      ]
      [
        ifelse (min incomes = item 2 incomes)
        [
          set sec_state "Econ_3_low"
        ]
        [
          show (word "Error, income: " (min incomes) " doesn't exist in " incomes)
        ]
      ]
    ]
  ]
  [
    set sec_state "All is well"
  ]

end

;;Economies

;;Sets up a single economy of a type
to economies.setup [econ_type]

  ;;Initial unemployment at 4% for testing purposes
  ;;Hint to self, initial_population is accessible because it is a global variable
  let workers floor((initial_population * ((100 - initial_unemployment) / 100)) / 6)

  ;;We initialize the list of our workplaces
  set workplaces (List workers workers )

  ;;And set various necessary starting values
  set salaries initial_salaries
  set profits (list (initial_wealth / 6))
  set output (list workers)

  ;;Set up what type of economy we are, and which resources we make (1) or consume (-1)
  ifelse(econ_type = 0)
  [
    set etype "Production"
    set resources [1 1 1 -1 0 0]
  ]
  [
    ifelse econ_type = 1
    [
      set etype "Industrial"
      set resources [ 0 -1 -1 1 1 1]
    ]
    [
      set etype "Service"
      set resources [0 0 0 0 -1 -1]
    ]
  ]


  ;;Set up information for states, as well as our 1-1 list of states and actions
  set econ_state  "Low profits"
  set econ_states (List "Low_workforce_high_profits" "Low_workforce_low_profits" "Low_profits" "All_is_well")

  let raise_wages [[] ->
    set salaries (salaries + (salaries / 10))
  ]

  let relax [[] ->
  ]

  let lower_wages [[] ->
    set salaries  max (list (salaries - (salaries / 10)) 0) ;;All salaries cannot fall below 0
  ]
  let error_handling [[x] ->
    show (word  "An error occured. The state "  x   " does not exist")
  ]

  set econ_actions (List raise_wages  raise_wages lower_wages relax error_handling)
end

;;Runs on each economy once per timestep
to economies.update

  ;;Calculate how many workplaces the economy can support
  calculate_workplaces

  ;;Calculate the economies money
  set profits lput (last profits + (economies.calculate_production etype)) profits

  ;;Find the current state of the economy and execute appropriate action
  economies.find_state
  switch econ_state econ_states econ_actions self
end

;;Calculates what the economy is producing and at what cost, as well as how much the economy profits
to-report economies.calculate_production [ economy_type]

  ;;We find the economy and relevant classes
  let econ self
  let owner one-of governments with [member? econ [econs] of pr_sector or member? econ [econs] of pu_sector]
  let owner_market [internal_market] of owner

  ;;Find what resources we want and the market availability and prices
  let relevant_items []
  let i 0
  foreach resources [ x ->
    ;;If the item found is relevant to the nation (not a 0 in the list)
    ifelse(x != 0)
    [
      ;;Set that entry in our list to be eual to the number of that item available on the market,
      ;;and the individual price of said item multiplied by whether we are buying (item registered as -1) or selling(item registered as 1)
      set relevant_items lput (list (item i last [ressources] of owner_market) ((item i last [prices] of owner_market) * x)) relevant_items
    ]
    [
      ;;Else we set the entry to [0, 0]
      set relevant_items lput (list 0 0) relevant_items
    ]
    set i i + 1
  ]

  ;;Find how much we expect to need of items

  ;;Find what the least amount we need is
  ;;For this we assume that every workplace needs 1 of each item identified as needed (-1)
  let max_input item 0 workplaces

  ;;Then go through each relevant item and check if the market availability for that item is lower than the amount needed
  foreach relevant_items [ x ->
    if( item 1 x < 0 and item 0 x < max_input)
    [
      ;;If it is lower, set the new max to be equal to the value found
      set max_input item 0 x
    ]
  ]

  ;;Find price of all materials needed in the work process
  let material_cost 0
  foreach relevant_items [ x ->
    if( item 1 x < 0)
    [
      set material_cost material_cost + item 1 x
    ]
  ]

  ;;If that price is higher than our budget, we instead have to reduce the amount of produce we make
  if( abs (material_cost * max_input) > last profits)
  [
    set max_input floor( last profits / abs material_cost)
  ]

  ;;Max cannot go below 0
  set max_input max (list max_input 0)


  ;;Now, max_input ought to be the maximum amount of resources purchaseable.
  ;;So now we need to figure out if that would turn us a profit
  let cost 0
  let profit 0

  ;;GO through each item and if it is -1 increase the cost, if it is 1 increase the profit by the market value
  foreach relevant_items [x ->
    if(item 1 x < 0)
    [
      set cost cost + (item 1 x * max_input)
    ]
    if(item 1 x > 0)
    [
      set profit profit + (item 1 x * max_input)
    ]
  ]

  ;;Service jobs produce nothing

 if etype = "Service"
 [
    let buyers last [population] of owner - last [unemployment] of owner
    ifelse (buyers > 0)
    [
      set profit max (list (max_input * (last [gdp] of owner / buyers)) 0)
    ]
    [
      set profit 0
    ]
  ]

  ;;Combine the total cost of items with the total cost of taxation on market items, and the cost of labor
  let total_costs cost + (cost * ([taxes] of owner / 100)) - (salaries * item 0 workplaces)

  ;;Combine total profit with the cost of taxes being applied to the market value
  ;;Then also remove the taxes on income
  let total_profit profit - (profit * ([taxes] of owner / 100))
  set total_profit total_profit - (total_profit * ([taxes] of owner / 100))

  ;;If the total profit + the total costs (which are negative)  is larger than 0, or at least less of a loss than just not doing any work, we work. Else, we do not.
  ifelse(total_profit + total_costs > 0 or total_profit + total_costs > (( salaries * item 0 workplaces) * -1))
  [
    ;;Working is more profitable than not working
    report economies.make_purchases max_input owner_market owner
  ]
  [
    ;;Not working is better than working, ironically, so we do nothing with the industry that year
    ;;The worst case scenario, where paying salaries for nothing is less of a loss than trying to buy materials.
    set output lput 0 output
    report (salaries * item 0 workplaces)* -1

  ]
end

;;Function which buys items from the market and sells items to it
to-report economies.make_purchases [input owner_market owner_nation]

  let costs 0
  let profit 0
  let i 0

  ;;For every resource make purchases and sales
  foreach resources [ x ->
    if( x < 0)
    [
      ask owner_market[
        set costs costs + markets.purchase i input
      ]
    ]
    if(x > 0)
    [
      let product input + (input * random-float 0.25)
      ask owner_market
      [
        set profit profit + markets.sell i product
      ]
    ]
    set i i + 1
  ]

  if(etype = "Service")
  [
   let buyers last [population] of owner_nation - last [unemployment] of owner_nation
   set profit max (list (input * (last [gdp] of owner_nation / buyers)) 0)
  ]

  ;;Save nations last production as the total output for this year
  set output lput input output

  set costs costs + ( salaries *  item 0 workplaces)


  ;;Deduct taxes from income and add them to the owners funding
  let taxation profit * ([taxes] of owner_nation / 100)
  ask owner_nation
  [
    set public_funding replace-item (length public_funding - 1) public_funding (last public_funding + taxation)
  ]

  set profit profit - taxation

  ;;Report the real profit of transaction, which might be different from the anticipated output
  report profit - costs

end

;;Find the state of the economy
to economies.find_state


  let prof_difference 0
  let sector myself ;;(The sector is one layer up from this function. Messy messy)

  ;;If we are not in year 0, During which we have no previous year to compare to
  if( year > 1)
  [
    ;;Profits made between last year and this year
    set prof_difference last profits - (item ((length profits) - 2) profits)

  ]


  ;;If we have profit growth
  let high_profits prof_difference > 0

  ;;If we have free workplaces
  let low_workforce  item 0 workplaces < item 1 workplaces


  ifelse high_profits
  [
    ifelse low_workforce
    [
      set econ_state "Low_workforce_high_profits"
    ]
    [
        set econ_state "All_is_well"
    ]
  ]
  [
     ifelse low_workforce
    [
      set econ_state "Low_workforce_low_profits"
    ]
    [
        set econ_state "Low_profits"
    ]
  ]
end

;;Markets

;;Sets up the market with all the resources and their prices
to market.setup
  ;;             [ 0=Forrestry,    1=Mining,   2=Fuel,   3=Mechanics, 4=Electricity,  5=Electronics]
  set ressources [[   100000        100000     100000      100000         100000          100000]]

  set prices [[        1              2.5        3            5             7.5             15]]
end


;;Update the lists so we have a value for next year
to market.update
  set ressources lput last ressources ressources
  set prices lput last prices prices
end

;;Updates the prices of the market items based on how many of them there are
to market.update_prices

  let forrestry  market.price_calc 1 (item 0 (last ressources))
  let mining market.price_calc  2.5 (item 1 (last ressources))
  let fuel market.price_calc 3 (item 2 (last ressources))
  let mechanics market.price_calc 5 (item 3 (last ressources))
  let Electricity market.price_calc 7.5 (item 4 (last ressources))
  let Electronics market.price_calc 15 (item 5 (last ressources))

  let new_prices (list forrestry mining fuel mechanics Electricity Electronics )
  set prices replace-item  (length prices - 1) prices new_prices

end

;;Makes a purchase from the market and returns the buy price + taxes
to-report markets.purchase [index quantity]
  let new_ressources replace-item index (last ressources) (item index (last ressources) - quantity)
  set ressources replace-item (length ressources - 1)  ressources new_ressources
  let buy (quantity * item index last prices)
  let taxation buy  * ([taxes] of market_owner / 100)
  ask market_owner [
    set public_funding replace-item (length public_funding - 1) public_funding ((last public_funding) + taxation)
  ]
  market.update_prices
  report buy + taxation
end

;;Same thing as above, but now selling items rather than buying
to-report markets.sell [index quantity]
  let new_ressources replace-item index (last ressources) (item index (last ressources) + quantity)
  set ressources replace-item (length ressources - 1)  ressources new_ressources
  let sale (quantity * item index last prices)
  let taxation sale  * ([taxes] of market_owner / 100)
  ask market_owner [
    set public_funding replace-item (length public_funding - 1) public_funding ((last public_funding) + taxation)
  ]
  market.update_prices
  report sale - taxation
end

;;Calculates the price of an item on a scale
to-report market.price_calc [initial_value current_value]
  ifelse( current_value != 0)
  [

    report (initial_value / (current_value ^ 0.5)) * 10
  ]
  [
    report initial_value * 100
  ]
end

;;Other

;;Function which essentially runs a switch statement
to switch [argument possible_values actions target]
  let pos position argument possible_values
  ifelse pos != false ;;If the argument exists in the list of accepted values, run the action mapped to that value
  [
    ask target [
      run item pos actions
    ]
  ]
  [;;If the argument does not exist, run the last action in the list, which should be error handling

    ask target [
      (run last actions argument)
    ]
  ]
end

;;Function which calculates population growth for a government
to-report pop_growth

  ;;Births per woman

  ;;births per Woman = 7 - education - urbanization * unemployment (7 - 0.5)

  ;;Urbanization can be measured by seeing how large economies 2 and 3 are compared to economy 1
  ;;For both sectors of course

  ;;min gdp , min migration
  ;;max gdp, max migration
  ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)

  let economy_difference (list 0 0)

  ;;Find how much of our private sector is urbanized
  ask pr_sector[
    let diff (list )
    ask econs [
      ifelse(etype = "Production")
                [
                  set diff insert-item 0 diff last profits
      ]
      [
        set diff lput last profits diff
      ]
    ]
    let difference item 0 diff / (item 1 diff + item 2 diff)

    set economy_difference replace-item 0 economy_difference difference
  ]

  ;;Find how much of our public sector is urbanized
  ask pu_sector [
       let diff (list )
    ask econs [
      ifelse(etype = "Production")
                [
                  set diff insert-item 0 diff last profits
      ]
      [
        set diff lput last profits diff
      ]
    ]
    let difference item 0 diff / (item 1 diff + item 2 diff)

    set economy_difference replace-item 1 economy_difference difference
  ]

  ;;Gives us a percentage impact between 0 and 33% on the total impact
  ;;Economy difference = 0 Worst, 33%
  ;;Economy difference = 100 best, 0%
  let urbanization max (list  min ( list  (33 - (33  * mean economy_difference)) 33 ) 0)

  ;;Finding impact of education
  ;;x0,y0 = min average education, max death-rate
  ;;X1,y1 = max average education, min death-rate
  ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)
  let yp 33 + ((0 - 33) / (1 - 0)) * ((((last public_funding * item 1 budget)  + 1)  / (last population + 1)) - 0)
  let education_impact min (list (max (list yp 0)) 33)


  ;;Finding impact of unemployment, which is flipped by urbanization
  ;;As urbanization and education rises, unemployment goes from positive to negative
  ;;x0,y0 = Max unemployment, Max impact
  ;;x1,y1 = min unemployment, min impact
  ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)
  ;;  33 + 33 * 0 = 0 or 33
  ;; 33 + 33 * -1 = - 66
  set yp 33 + ((0 - 33) / (0 - 1)) * ((last unemployment / last population) - 1)
  let unemployment_impact min (list (max (list yp 0)) 33)

  let birthrate_factors education_impact + urbanization

  ifelse birthrate_factors > 50
  [
    set birthrate_factors birthrate_factors + unemployment_impact
  ]
  [
    set birthrate_factors birthrate_factors - unemployment_impact
  ]

  set birthrate_factors min (list (max (list birthrate_factors 0)) 100)

  let Max_births_per_woman (Max_crude_birthrate / 1000 ) / 2
  let Min_births_per_woman (Min_crude_birthrate / 1000) / 2

  ;;We find the final birthrate by checking how much the impact of the detrimental factors has removed us from the max birthrate
  let birthrate Max_births_per_woman - (((Max_births_per_woman - Min_births_per_woman) / 100) * birthrate_factors)

  let deathrate_factors []

  set yp 13 + ((1 - 13) / (Max_births_per_woman - Min_births_per_woman)) * (birthrate - Min_births_per_woman)
  let age_death_impact min (list (max (list yp 1)) 13) ;;Has to be between 1 and 13
  set deathrate_factors lput age_death_impact deathrate_factors


  ;;x0,y0 = min-gdp, max death-rate
  ;;x1,y1 = max-gdp, min death-rate
  set yp 13 + ((1 - 13) / ((initial_wealth * 1000) - 0.1)) * (last gdp - 0.1)
  let gpd_death_impact min (list (max (list yp 1)) 13)
  set deathrate_factors lput gpd_death_impact deathrate_factors

  ;;x0,y0 = min average education, max death-rate
  ;;X1,y1 = max average education, min death-rate
  set yp 13 + ((1 - 13) / (1 - 0)) * ((((last public_funding * item 1 budget)  + 1)  / (last population + 1)) - 0)
  let education_death_impact min (list (max (list yp 1)) 13)
  set deathrate_factors lput education_death_impact deathrate_factors

  ;;x0,y0 = min unemployment, min death-rate
  ;;x1,y1 = max unemployment, max death-rate
    ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)
  set yp 1 + ((13 - 1) / (100 - 0)) * (( last unemployment / last population) - 0)
  let unemployment_factors min (list (max (list yp 1)) 13)
  set deathrate_factors lput unemployment_factors deathrate_factors

  let deaths last population * ((mean deathrate_factors) / 1000) ;; deathrate is usually calculated by 1000, we have to divide by 1000 to get per person

  let women (last population - deaths) / 2

  ;;Population growth = living women * births per woman
  let births women * birthrate

  ;;Migrations seems to mostly be based on GDP and population
  ;;min gdp , min migration
  ;;max gdp, max migration
  ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)
  let migration_factors []
  let max_migration (last population) / 100
  let min_migration max_migration * -1

  set yp  (min_migration + ((max_migration - min_migration) / ((initial_wealth * 1000) - 0.1)) * (last gdp - 0.1))
  let gdp_migration_impact min (list (max (list yp min_migration)) max_migration)
  set migration_factors lput gdp_migration_impact migration_factors

  ;;min population, min migration
  ;;Max population, max migration
  set yp (min_migration + ((max_migration - min_migration ) / ((initial_population * 100) - 0)) * (last population - 0))
  let population_migration_impact min (list (max (list yp min_migration))max_migration)
  set migration_factors lput population_migration_impact migration_factors

  let migration mean migration_factors

  report births + migration - deaths

end


;;Function which calculates population growth for a government
to-report pop_growth_2

  ;;(x0,y0) = (max-gdp,min-cbr)
  ;;(x1,y1) = (min-gdp,max-cbr)
  ;;(xp,yp) = (current-gdp, current-cbr)
  let min_birthrate 5
  let max_birthrate 50
  let yp  (min_birthrate + ((max_birthrate - min_birthrate) / (0.1 - (initial_wealth * 1000))) * (last gdp - (initial_wealth * 1000)) )
  let birthrate (min (list (max (list yp  min_birthrate)) max_birthrate)) / 1000 ;;Crude birthrate is per 1000 people, we need to reduce that to per person



  ;;Deathrate is related to population age (lower birthrates means higher average population age), socio-economic status (gdp), and education
  let deathrate_factors []

  ;;x0,y0 = min-birthrate, max death-rate
  ;;x1,y1 = max-birthrate, min death-rate
  set yp 13 + ((1 - 13) / (max_birthrate - min_birthrate)) * ((birthrate * 2) - min_birthrate)
  let age_death_impact min (list (max (list yp 1)) 13) ;;Has to be between 1 and 13
  set deathrate_factors lput age_death_impact deathrate_factors

  ;;x0,y0 = min-gdp, max death-rate
  ;;x1,y1 = max-gdp, min death-rate
  set yp 13 + ((1 - 13) / ((initial_wealth * 1000) - 0.1)) * (last gdp - 0.1)
  let gpd_death_impact min (list (max (list yp 1)) 13)
  set deathrate_factors lput gpd_death_impact deathrate_factors

  ;;x0,y0 = min average education, max death-rate
  ;;X1,y1 = max average education, min death-rate
  set yp 13 + ((1 - 13) / (1 - 0)) * ((((last public_funding * item 1 budget)  + 1)  / (last population + 1)) - 0)
  let education_death_impact min (list (max (list yp 1)) 13)
  set deathrate_factors lput education_death_impact deathrate_factors

  let deathrate (mean deathrate_factors) / 1000 ;; deathrate is usually calculated by 1000, we have to divide by 1000 to get per person

  ;;Migrations seems to mostly be based on GDP and population
  ;;min gdp , min migration
  ;;max gdp, max migration
  ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)
  let migration_factors []
  let max_migration (last population) / 100
  let min_migration max_migration * -1

  set yp  (min_migration + ((max_migration - min_migration) / ((initial_wealth * 1000) - 0.1)) * (last gdp - 0.1))
  let gdp_migration_impact min (list (max (list yp min_migration)) max_migration)
  set migration_factors lput gdp_migration_impact migration_factors

  ;;min population, min migration
  ;;Max population, max migration
  set yp (min_migration + ((max_migration - min_migration ) / ((initial_population * 100) - 0)) * (last population - 0))
  let population_migration_impact min (list (max (list yp min_migration))max_migration)
  set migration_factors lput population_migration_impact migration_factors

  let migration mean migration_factors

  report ((birthrate - deathrate) * last population) + migration
  end

to divide_workforce

  let available_workers  0

  ifelse( year > 1)
  [
    ;;Available workers =                     new workers in the workpool this year             +   the unemployed from last year
    set available_workers floor ((last population - (item (length population - 2) population))  + (last unemployment))
  ]
  [
    set available_workers  floor ((last population))
  ]

  let all_econs []
  ask pr_sector
  [
    ask econs [
      set all_econs lput self all_econs
    ]
  ]
  ask pu_sector
  [
    ask econs [
      set all_econs lput self all_econs
    ]
  ]
  set all_econs turtle-set all_econs

  ifelse(available_workers >= 0)
  [

    ;;For each economy with open workplaces
    let available_econs all_econs with [item 0 workplaces < item 1 workplaces ]

    while [(available_workers > 0) and (count available_econs > 0 ) ]
    [
      ask available_econs with-max [salaries]
      [
        let openings item 1 workplaces - item 0 workplaces
        ifelse (openings >= available_workers)
        [
          set workplaces (list (item 0 workplaces + available_workers) item 1 workplaces)
          set available_workers 0
        ]
        [
          set workplaces (list item 1 workplaces item 1 workplaces)
          set available_workers available_workers - openings
        ]
      ]
      set available_econs all_econs with [ item 0 workplaces < item 1 workplaces ]
    ]

    set unemployment lput max (list (available_workers) 0)  unemployment ;;No negative unemployment

  ]
  [;;We have lost populationin the last year

    let lost_workplaces abs available_workers

    let unemployed_workers last unemployment


    ifelse( unemployed_workers > lost_workplaces)
    [
      set unemployed_workers (unemployed_workers - lost_workplaces)
      set lost_workplaces 0
    ]
    [
      set lost_workplaces lost_workplaces - unemployed_workers
      set unemployed_workers 0
    ]

    let available_econs all_econs with [item 0  workplaces != 0]
    while [lost_workplaces > 0 and (count available_econs > 0)]
    [
      ask one-of available_econs with-min[salaries]
      [
        ifelse( item 0 workplaces > lost_workplaces)
        [
          set workplaces (list ( item 0 workplaces - lost_workplaces) (item 1 workplaces))
          set lost_workplaces 0
        ]
        [
          set lost_workplaces lost_workplaces - item 0  workplaces
          set workplaces (list (0) (item 1 workplaces))
        ]
      ]
      set available_econs all_econs with [item 0 workplaces != 0]
    ]

    set unemployment lput  unemployed_workers  unemployment
  ]

end

to calculate_workplaces

  let max_workplaces max (list (floor (last profits /  salaries)) 0) ;;No less than 0 workplaces

  let workers []

  ifelse(item 0 workplaces > max_workplaces)
  [
    set workers (list max_workplaces max_workplaces)
    ;;Ask governments where the calling economy is a member of one of the governments sectors
    ask governments with [member? myself [econs] of pr_sector or member? myself [econs] of pu_sector]
    [
      ;; Replace the last item in unemployment with
      set unemployment replace-item (length unemployment - 1) unemployment (last unemployment + ((item 0 [workplaces] of myself - max_workplaces)))
    ]
  ]
  [
    set workers (list item 0 workplaces max_workplaces)
  ]

  set workplaces workers
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
2
10
65
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
134
10
197
43
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
68
10
131
43
Run
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
0
46
206
79
initial_population
initial_population
10000
100000
100000.0
100
1
citizens
HORIZONTAL

SLIDER
0
81
200
114
initial_wealth
initial_wealth
100
1000000
999900.0
100
1
$
HORIZONTAL

INPUTBOX
0
118
155
178
Runtime
100.0
1
0
Number

PLOT
656
13
1391
163
Government profits
years
gdp log 10
0.0
100.0
0.0
20.0
true
false
"" ""
PENS
"GDP" 1.0 0 -16777216 true "" "let cash 0\nask governments[ \n set cash last gdp\n]\nplot log cash 10"

PLOT
656
167
1389
317
Government population
NIL
NIL
0.0
100.0
0.0
50000.0
true
false
"" ""
PENS
"Pop" 1.0 0 -16777216 true "" "let pop 0\nask governments [\nset pop last population\n]\n\nplot pop"

PLOT
657
322
1391
472
Government approval
NIL
NIL
0.0
100.0
0.0
100.0
false
false
"" ""
PENS
"Approval" 1.0 0 -16777216 true "" "let app 0\nask governments[\n set app approval\n]\nplot app"

PLOT
657
476
1394
626
Sector profits
NIL
NIL
0.0
100.0
0.0
12500.0
true
false
"" ""
PENS
"Private Sector" 1.0 0 -16777216 true "" "let prof 0\nask private_sectors [\nset prof last profits\n]\nplot prof"
"Public Sector" 1.0 0 -7500403 true "" "let prof 0\nask public_sectors[\n set prof last profits\n]\n\nplot prof"

PLOT
19
449
647
627
Economies
Years
Profits log 10
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"Econ-1" 1.0 0 -16777216 true "" "let prof 0\nask private_sectors [\n ask econs with [etype = \"Production\"]\n [\n  set prof last profits\n ]\n]\nplot log (prof + 1) 10"
"Econ-2" 1.0 0 -7500403 true "" "let prof 0\nask private_sectors [\n ask econs with [etype = \"Industrial\"]\n [\n  set prof last profits\n ]\n]\nplot log (prof + 1) 10"
"Econ-3" 1.0 0 -2674135 true "" "let prof 0\nask private_sectors [\n ask econs with [etype = \"Service\"]\n [\n  set prof last profits\n ]\n]\nplot log (prof + 1) 10"
"pu_Econ_1" 1.0 0 -13840069 true "" "let prof 0\nask public_sectors [\n ask econs with [etype = \"Production\"]\n [\n  set prof last profits\n ]\n]\nplot log (prof + 1) 10"
"pu_Econ_2" 1.0 0 -6459832 true "" "let prof 0\nask public_sectors [\n ask econs with [etype = \"Industrial\"]\n [\n  set prof last profits\n ]\n]\nplot log (prof + 1) 10"
"pu_Econ_3" 1.0 0 -1184463 true "" "let prof 0\nask public_sectors [\n ask econs with [etype = \"Service\"]\n [\n  set prof last profits\n ]\n]\nplot log (prof + 1) 10"

MONITOR
24
632
140
677
Government taxes
[taxes] of government 0
17
1
11

PLOT
656
632
1397
782
Government unemployment
NIL
NIL
0.0
100.0
0.0
100000.0
true
false
"" ""
PENS
"Worker Unemployment" 1.0 0 -16777216 true "" "let workers 0\nask governments [\nset workers last unemployment\n]\nplot workers"

MONITOR
154
632
304
677
Workplaces
sum [item 0 workplaces] of economies
17
1
11

MONITOR
310
633
453
678
Total unemployment
item 0 [last unemployment ] of governments
17
1
11

MONITOR
24
683
170
728
Total population
item 0 [last population] of governments
17
1
11

MONITOR
178
684
318
729
Available workplaces
sum [item 1 workplaces] of economies
17
1
11

MONITOR
23
735
177
780
Education funding
item 0 [last public_funding] of governments * item 1 item 0 [budget] of governments
17
1
11

PLOT
1396
14
1980
164
Resources
years
Amount
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Forrestry" 1.0 0 -14333415 true "" "let amount 0\nask markets [\nset amount item 0 last ressources\n]\nplot amount"
"Mining" 1.0 0 -7500403 true "" "let amount 0\nask markets [\nset amount item 1 last ressources\n]\nplot amount"
"Fuel" 1.0 0 -2674135 true "" "let amount 0\nask markets [\nset amount item 2 last ressources\n]\nplot amount"
"Mechanics" 1.0 0 -955883 true "" "let amount 0\nask markets [\nset amount item 3 last ressources\n]\nplot amount"
"Electricity" 1.0 0 -8990512 true "" "let amount 0\nask markets [\nset amount item 4 last ressources\n]\nplot amount"
"Electronics" 1.0 0 -14737633 true "" "let amount 0\nask markets [\nset amount item 5 last ressources\n]\nplot amount"

SLIDER
0
182
209
215
Initial_unemployment
Initial_unemployment
0
100
6.0
1
1
% of population
HORIZONTAL

SLIDER
0
218
209
251
initial_salaries
initial_salaries
0
10
1.5
0.5
1
$
HORIZONTAL

PLOT
1398
173
1879
393
Use of taxes
years
percentage of taxes
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Public sector funds" 1.0 0 -16777216 true "" "plot item 0 [ item 0 budget] of governments * 100"
"Education funds" 1.0 0 -7500403 true "" "plot item 0 [item 1 budget] of governments * 100"

SLIDER
0
255
213
288
Max_crude_birthrate
Max_crude_birthrate
0
50
27.0
1
1
NIL
HORIZONTAL

SLIDER
0
290
216
323
Min_crude_birthrate
Min_crude_birthrate
0
50
10.0
1
1
bpw
HORIZONTAL

PLOT
1400
400
1879
550
Population growth
Years
Percent
0.0
100.0
-2.0
2.0
true
true
"" ""
PENS
"Pop growth rate" 1.0 0 -16777216 true "" "let growth 0\nask governments [\nifelse year > 1\n[\n set growth ((last population - item (length population - 2) population ) / last population) * 100 \n]\n[\nset growth 0\n]\n]\n\nplot growth"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
