extensions [ csv ]

breed [nations nation]
breed[ governments government]
breed [markets market]
breed [events event]


;;Tasks:
;;Set up education and welfare calculations X
;;-Welfare matters only for approval purposes X
;;-Education goes into the tech-level for products and into pop growth
;;--Tech X
;;-- Pop growth X

;;Set up ethics calculations
;;-figure out how to calculate ethics impact on approval TEMP X
;;-figure out how to add ethics into decision making TEMP X

;;Update variables based on education, welfare, ethics X

;;Finish setting up pop_growth X

;;Debug functions to work properly
;;-Trade function needs rejigging NOPE IT DONT
;;-Updating values of resources X

;;Figure out why tf my nation wealth jumps all over the place and my population continuosly decreases
;;Wealth jumps X
;;Pop growth X

;;Set up output

;;Set up R

;;Make the diplomacy portion of the code

;;Update output

;;Make thesis





nations-own [
  ;;Nations identifier
  name

  ;;The nations wealth
  wealth_over_time

  ;;The nations population
  population_over_time


  ;;How large a portion of the population can work (L)
  labor

  ;;The nations resources (P)
  resources_over_time

  ;;The nations technology level for each resource (Pnl)
  technology_levels

  ;;How much the nation wants any specific good
  desires

  ;;Value of each resource
  resource_values

  ;;The values of the nation
  ethics

  ;;Turtle variables

  ;;The government of the nation
  national_government

  ;;other nations in the program
  neighbours

  ;;Market
  international_Market

  ;;The number of trades made [Good trade, bad trade, no exports, no labor]
  trades
]

governments-own[
  ;;The nation that owns the government
  owner

  ;;How much of the salary of a worker is taken by the government
  taxes

  ;;How well liked the current government is
  approval

  ;;Collected tax money
  public_funding

  ;;Public funding percentage [Public_sector][Education]
  budget

]

markets-own [

  ;;How much the market owns of each resource
  international_resource_storage
  ;;Logs how much of each resource is sold and bought each year
  international_resource_log

  ;;How much each good costs
  international_prices

  ;;How much each good is worth initially
  initial_prices
]

events-own [
  ;;Name describing the nature of the recorded event
  event_type

  ;;The timesteps between which the event occured
  time

  ;;The nation which owns this event
  owner

  ;;Relevant data for the event, here mostly just a number
  data
]

globals [
  seed
  year ;;current year
  name_list
  resource_list
  number_of_nations
  number_of_products
  commands
  runs
  reruns
  csv_list
  years_for_statistics
  events_list
  tech_price
  Min_crude_birthrate
  Max_crude_birthrate
]

;;Setup Functions

to clear
  clear-all
  reset-ticks
  file-close-all
end

to setup

  clear-ticks
  clear-turtles
  clear-drawing
  clear-all-plots
  clear-output
  reset-ticks
  file-close-all

  ifelse(file-exists? source_file)
  [
    nationsim.file_setup
  ]
  [
   nationsim.interface_setup
  ]
end

to nationsim.file_setup

 Nationsim.get_nation_variables

  ask nations [
    set neighbours other nations
  ]

  create-markets 1 [
    markets.setup (number_of_products)
    ask nations [
      set international_Market myself
    ]
  ]

  ask one-of markets [
    set initial_prices nations.find_international_prices
    set international_prices replace-item 0 international_prices initial_prices
  ]

end

to nationsim.interface_setup
  set reruns times_to_run_the_simulation
  set min_crude_birthrate minimum_crude_birthrate
  set max_crude_birthrate maximum_crude_birthrate
  set tech_price Price_of_technology
  set number_of_nations nation_count
  set number_of_products number_of_resources
  set years_for_statistics Length_of_statistics_intervals
  set name_list ( list 1 "Germany" "France" "Norway" "Britain" "Sweden" "Finland" "Denmark" "Italy" "Spain" "Portugal" )
  set  resource_list  (list (list "Agriculture" 1) (list "Fishing" 1) (list "Mining" 1) (list "Forestry" 1) (list "Hunting" 1) (list "Constuction" 2) (list "Production" 2) ( list "Energy" 2) (list "Retail" 3) (list "Services" 3) (list "Real-Estate" 3))
  set seed (Random reruns - random reruns)
   create-nations number_of_nations[
    nations.setup
    hatch-governments 1 [
      set owner myself
      ask owner [
        set national_government myself
      ]
      governments.setup
    ]
  ]

   create-markets 1 [
      markets.setup (number_of_products)
     ask nations [
      set international_Market myself
    ]
    ]

    ask one-of markets [
      set initial_prices nations.find_international_prices
    set international_prices replace-item 0 international_prices initial_prices
    ]

end

to go
  if(runs = 0 and year = 0)
  [
    clear
    if( seed = 0)
    [
      set seed new-seed
    ]
    random-seed seed
    setup
    csv_init
  ]
  ifelse(runs < reruns)
  [
    ifelse(year < runtime)
    [
      set year (year + 1)

      ;; ask governments[
      ;; governments.update
      ;;]
      ask nations [
        if( last population_over_time <= 0)
        [
          ask national_government [ die]
          set number_of_nations number_of_nations - 1
          die
        ]
      ]

      ask markets[
        markets.update
      ]
      ask governments[
        governments.update
      ]

      ask nations[

        let trade_result nations.trade international_market
        ifelse(item 0 trade_result)
        [
          let trade last trades
          set trade replace-item 0 trade (item 0 trade + 1)
          set trades lput trade trades
          if(debug)
          [
            show (word "Trade was a success!")
            show item 1 trade_result
          ]
        ]
        [
          ;;show item 1 trade_result
          if(item 2 trade_result = 0)
          [
            let trade last trades
            set trade replace-item 3 trade (item 3 trade + 1)
            set trades lput trade trades
            if(debug)
            [
              show ( "Trade failed due to no available labor")
              show item 1 trade_result
            ]
          ]
          if(item 2 trade_result = 1)
          [
            let trade last trades
            set trade replace-item 2 trade (item 2 trade + 1)
            set trades lput trade trades
            if(debug) [
              show ("Trade failed due to no available export resources")
              show item 1 trade_result
            ]
          ]
          if(item 2 trade_result = 3)
          [
            let trade last trades
            set trade replace-item 1 trade (item 1 trade + 1)
            set trades lput trade trades
            if(debug)
            [
              show ("Trade failed to produce profits")
              show item 1 trade_result
            ]
          ]
        ]
        set wealth_over_time lput (sum item 1 trade_result) wealth_over_time
        set resources_over_time lput item 1 trade_result resources_over_time
        nations.find_resource_values
        nations.update_labor
        nations.update_desires
      ]
      if(file-exists? source_file)
      [
        nationsim.execute_commands
      ]
      tick
    ]
    [
      let i runs
      csv_record_run
      let record csv_list
      let SGSV seed
      clear-all
      set runs (i + 1)
      set csv_list record
      set seed SGSV
      random-seed seed
      setup
    ]
  ]
  [
    finish
    clear
    stop
  ]
end

to nations.setup

  let name_index item 0 name_list
  set name item name_index name_list

  ;;Update the index for the next nation
  set name_list replace-item 0 name_list ((item 0 name_list) + 1)

  set wealth_over_time (list initial_wealth)

  set population_over_time (list ((random initial_population_max) + initial_population_min))

  set labor (list first population_over_time)

  set resources_over_time (list n-values number_of_products [random 2000])

  set ethics (list (list "Welfare" ((random 99) + 1)) ( list "Education" ((random-float 99) + 1)) ( list "Mercantile" ((random-float 99) + 1)) )

  ;;Find techology for each product, each being between 1 and 5
  set technology_levels (list n-values number_of_products [precision ((random-float 4) + 1) 2])

  ;;Desires is how much of a product each person in the nation wants at minimum
  set desires (list n-values number_of_products [precision (0.01 + random-float 0.99) 2])

  let r_values []
  let i 0
  while [i < number_of_products]
  [
    ;;We set 0 as the minimum value for any item, as no item can have negative value
    set r_values lput (precision (item i last desires)2) r_values
    set i i + 1
  ]
  set resource_values (list r_values )
  set neighbours other nations
  set trades (list (list 0 0 0 0 ) )
end

to nations.file_setup

  set name nationsim.read

  set wealth_over_time nationsim.read

  set population_over_time nationsim.read

  set labor nationsim.read

  set resources_over_time nationsim.read

  set technology_levels nationsim.read

  set desires nationsim.read

  set ethics nationsim.read

  set resource_values []

  let i 0

  set resource_values (list last desires )

  set trades (list (list 0 0 0 0) )

end

to-report nations.find_international_prices

  let prices []

  ask nations [
    let price []
    let i 0
    while [i < number_of_products]
    [

      set price lput (item i last resource_values) price
      set i i + 1
    ]
    set prices lput price prices
  ]

  ;;prices[ nations-prices[ item 1 item 2 item 3 ] [item 1 item 2] ]
  ;;
  ;;

  let inter_prices []
  let i 0

  while [i < length resource_list]
  [

    let inter_price 0
    let national_prices []

    foreach prices [ x ->
      if (length x > i)
      [
        set national_prices lput item i x national_prices
      ]
    ]

    ;;national_prices [item 1 item 1]   [ item 2 item 2]  [item 3]

    set national_prices sort national_prices

    ;;Then we find a mid_point
    if(length national_prices > 0)
    [
      set inter_price mean national_prices
    ]

    set inter_prices lput inter_price inter_prices
    set i i + 1
  ]

  report inter_prices
end


;;Calculate the production in autarky for a nation
;;Inputs
;; -R: The labor the nation has available for resource creation in autarky. Float
;; -labor_values: The value 1 point of labor has locally and internationally. [[local international] [...]]
;; -idesires: How much each resource is desires. [desire1 ...]
;;Reports
;; -Autarky outputs: How much worth for each resource we create in autarky. [Output1 ...]
to-report nations.find_autarky_outputs [R labor_values idesires]

  let desire_percentages []
  foreach idesires [ x -> set desire_percentages lput (x / sum idesires) desire_percentages]

  let i 0
  let autarky_outputs []
  foreach labor_values [ x ->
    set autarky_outputs lput (item 0 x * item i desire_percentages * R) autarky_outputs
    set i i + 1
  ]


  report autarky_outputs
end


;;Finds the good that creates the most profits when sold on the open market
;;Input:
;;-Labor values: How much any given resource is worth locally and internationally. [[local value  international value] [...]
;;Report:
;;- Export good: Index in resource_list for the good that maked the most money on the open market
to-report nations.find_export_good [labor_values]
  let EX []
  let i 0
  foreach labor_values [ x ->
    if(item 0 x < item 1 x)
    [
      set EX lput i EX
    ]
    set i i + 1
  ]

  if(length EX < 1)
  [
    report false
  ]
  set EX sort-by [[x y] -> item 1 item x labor_values > item 1 item y labor_values] EX

  report first EX
end


;;Calculates minimum desired outputs and remaining labor
;;Inputs:
;;-Labor values: How much any given resource is worth locally and internationally. [[local value  international value] [...]
;;-idesires: How much we desire any given resource. [desire1 ...]
;;-Labor: How large our available workforce is. integer
;;Returns:
;;list [Min_outputs R]
;; - Min_outputs: How much worth of each resource we want at the least. [min_output 1 ...]
;; - R: The remaining labor after generating our minimum outputs. float
to-report nations.calculate_min_outputs [labor_values idesires ilabor]

  ;;Step 1: Find how much each item is desired
  let min_outputs []
  let req_labor 0
  let i 0
  while [i < number_of_products]
  [
    set min_outputs lput (ilabor * item i idesires) min_outputs
    if(item i min_outputs = 0)
    [
      show "Min outputs is error"
      show min_outputs
    ]
    if(item 0 item i labor_values = 0)
    [
      show "Labor values is error"
      show labor_values
    ]
    set req_labor req_labor + (item i min_outputs / (item 0 item i labor_values))
    set i i + 1
  ]

  let R (ilabor - round req_labor)
  ;;Step 2: Calculate outputs in autarky

  ifelse(R < 0)
  [
    if(debug)
    [
      show "Recalculating"
    ]
    let labor_difference ilabor / req_labor
    let ndesires []
    foreach idesires [ x ->
      set ndesires lput (x * labor_difference) ndesires
    ]

    report nations.calculate_min_outputs labor_values ndesires ilabor
  ]
  [
    if(debug)
    [
      show (word "Labor Values: " labor_values )
      show (word "desires: " idesires)
      show (word "Labor " ilabor)
      show (word "minimum_outputs: " min_outputs)
      show (word "Remaining_labor " R)
    ]
    report (list min_outputs R)
  ]
end


;;function which finds how much we stand to make for each resource in trade
;;Input
;;-Labor values: How much any given resource is worth locally and internationally. [[local value  international value] [...]
;;-idesires: How much we desire any given resource. [desire1 ...]
;;-R: How large our available workforce is. Float
;;-EX: Index of our most profitable export good. Integer
;;Output
;; - Trade_values: How much worth of each product we produce. [output1 ...]
to-report nations.find_trade_value [labor_values idesires R EX]

  let trade_budget (item 1 item EX labor_values * R)

  let desire_percentages []
  foreach idesires [x -> set desire_percentages lput (x / sum idesires) desire_percentages]

  let Trade_values []
  let i 0
  foreach labor_values [ x ->
    set Trade_values lput (((trade_budget * item i desire_percentages) / item 1 x) * item 0 x ) Trade_values
    set i i + 1
  ]

  report Trade_values
end

;;Function returns true if the trade would generate money
to-report nations.find_trade_feasibility [labor_values EX]

  let H2 item 1 item EX labor_values


  let top 0

  foreach labor_values [x ->
      set top top + ( H2 / (item 1 x + 0.00000001))
  ]

  if(debug)
  [

    show (word "labor Values 2: " labor_values)

    show (word "Export goods: " EX)
    show (word "Top: " top)
    show (word "Bottom: " number_of_products)
  ]

  report top > number_of_products

  ;;report LS > RS
end

;;Function which returns true if the nation currently desires to make trade
to-report nations.find_trade_desireability
  let merc_desire item 1 one-of filter [ x -> item 0 x = "Mercantile"] ethics

  ;;War considerations
  ;;WIP

  ;;Profit loss considerations
  ;;WIP

  let total_desire merc_desire

  report (random 100 < total_desire) ;;If the random choice is less than the total desire, we want to trade
end

to-report nations.trade [inter_market]

  ;;Step 1: Find labor values
  let i 0

  let labor_values []
  while [ i < number_of_products]
  [
    let local_labor_value item i last technology_levels * item i last resource_values
    let international_labor_value item i last technology_levels * item i last [international_prices] of inter_market

    set labor_values lput (list local_labor_value international_labor_value)  labor_values
    set i i + 1
  ]

  ;;Step 2: Find Min_outputs and remaining labor

  let minR nations.calculate_min_outputs labor_values last desires last labor
  let min_outputs item 0 minR
  let R item 1 minR

  ;;If we have no labor to produce more with, we just report the min outputs
  if( R = 0)
  [
    report (list false min_outputs 0)
  ]

  let export_good nations.find_export_good labor_values

  ;;If we have nothing worth exporting we have to work in autarky
  if(export_good = false)
  [
     let autarky_production nations.find_autarky_outputs R labor_values last desires

    set i 0
    foreach min_outputs [ x ->
      set min_outputs replace-item i min_outputs (x + item i autarky_production)
      set i i + 1
    ]

    report (list false min_outputs 1)
  ]

  ;;Step 3: Find if the trade would be profitable and we feel like trading this year
  ifelse( nations.find_trade_feasibility labor_values export_good and nations.find_trade_desireability)
  [

    let desire_percentages []
    foreach last desires [ x -> set desire_percentages lput (x / sum last desires) desire_percentages]

    let production []
    ask inter_market
    [
      set production markets.sell_and_purchase export_good R desire_percentages
    ]

    set i 0
    foreach min_outputs [x ->
      set min_outputs replace-item i min_outputs (item i min_outputs + (item i production * item 0 item i labor_values ))
      set i i + 1
    ]

    report (list true min_outputs 2)
  ]
  [
    ;;find the autarky production instead
    let autarky_production nations.find_autarky_outputs R labor_values last desires

    set i 0
    foreach min_outputs [ x ->
      set min_outputs replace-item i min_outputs (x + item i autarky_production)
      set i i + 1
    ]

    report (list false min_outputs 3)
  ]
end

;;Function which calculates the values of individual resources
to nations.find_resource_values

  let min_outputs []
  let i 0
  while [i < number_of_products]
  [
    set min_outputs lput (last labor * item i last desires) min_outputs
    set i i + 1
  ]

  let new_values []
  set i 0

  ;;Find the difference between the last resource_output and the desired outputs
  ;;Find out how big a percentage of the desired output that difference is
  ;;Find the current price of the item (Demand / supply)
  ;;Make the new value the base price + the surplus/deficit
  ;;clamp price to be at least 0.01 to make sure to avoid division by 0 later down the line.
  foreach min_outputs [ x ->
    let difference x - item i last resources_over_time
    let percentage min (list max (list (difference / x) -0.1) 0.1) ;;No more than 10% growth/reduction each year to stabilize this nonesense
    let price item i last desires
    let value max (list (precision (price + (percentage * price)) 2) 0.01)
    set new_values lput value new_values
    set i i + 1
  ]

  set resource_values lput new_values resource_values
end

to nations.update_labor
  ;;WIP function that will be used for military module later
  set labor lput last population_over_time labor
end

to nations.update_desires
  ;;WIP function for programatical things that change desires.
  set desires lput last desires desires
end

;;MARKET FUNCTIONS


to markets.setup [resource-count]
  set international_resource_storage n-values resource-count [[[0 0]]]
  set initial_prices n-values resource-count [0]
  set international_prices (list n-values resource-count [0])
  set international_resource_log (list n-values number_of_products [(list 0 0)])
end

to markets.update

  let new_prices nations.find_international_prices
  set international_resource_log lput (n-values number_of_products [( list 0 0)]) international_resource_log
  set international_prices lput new_prices international_prices
end


;;Inputs:
;;Sell_index: The index of the resource to be sold in Resource_list
;;Sell_amount: How much of the resource should be sold
;;Desire_percentages: How much each resource in play is desired by the nation in question
;;Output:
;;How much of each resource has been purchased
to-report markets.sell_and_purchase [sell_index sell_amount desire_percentages]

  let ibudget markets.sell_item sell_index sell_amount
  let output n-values (length desire_percentages)  [0]

  let i 0
  foreach desire_percentages [ x ->
    let purchase_budget x * ibudget
    let purchase markets.purchase i purchase_budget
    set output replace-item i output (item i output + purchase)
    set i i + 1
  ]

  report output
end

to-report markets.sell_item [index amount] ;;ALL[ Resource[ Timestep[ [Sold Bought] ] ] ]
  let last_resource_value last (item index international_resource_storage)
  let sold_amount item 0 last_resource_value + amount
  let new_resource_value (list sold_amount item 1 last_resource_value)
  let updated_storage lput new_resource_value item index international_resource_storage
  set international_resource_storage replace-item index international_resource_storage updated_storage

  ;;log list[ year[ Resource[ sold bought] R[...] ] [...] ]

  let res_list item index last international_resource_log
  let new_res_value item 0 res_list + amount
  let new_res_list (list new_res_value item 1 res_list)
  let new_year_entry replace-item index last international_resource_log new_res_list
  set international_resource_log replace-item (length international_resource_log - 1) international_resource_log new_year_entry

  report amount * item index last international_prices
end

to-report markets.purchase [index ibudget]
  let last_resource_value last (item index international_resource_storage)
  let amount  (ibudget / item index last international_prices)
  let new_bought  (item 1 last_resource_value) + amount
  let updated_storage lput (list item 0 last_resource_value new_bought) item index international_resource_storage
  set international_resource_storage replace-item index international_resource_storage updated_storage

  let res_list item index last international_resource_log
  let new_res_value item 1 res_list + amount
  let new_res_list (list item 0 res_list new_res_value)
  let new_year_entry replace-item index last international_resource_log new_res_list
  set international_resource_log replace-item (length international_resource_log - 1) international_resource_log new_year_entry

  report  amount
end




;;GOVERMENT FUNCTIONS

to governments.setup
  ;;Taxes people pay as percentage
  set taxes (list (25.0 / 100))

  ;;Approval of people of the government as percentage
  set approval (list 50)

  ;;The budget for funding the public sector, recorded for each timestep
  set public_funding (list floor (first [wealth_over_time] of owner * last taxes))

  ;;The balance between budget for education and public funding in decimals, recorded for each timestep
  set budget (list (list 0.5 0.5))

end

to governments.file_setup
  set taxes nationsim.read
  set taxes (list (last taxes / 100))
  set approval nationsim.read

  set public_funding (list floor (first [wealth_over_time] of owner * last taxes))
  let ps nationsim.read

  set budget (list ( list ps (1 - (ps / 100)) ))
end

to governments.update
  ;;Find the new population of the nation
  let population floor pop_growth
  ask owner[
    set population_over_time lput (max (List ((last population_over_time) + population) 0)) population_over_time
  ]

  if(last [population_over_time] of owner > 0)
  [
    set public_funding lput (last [wealth_over_time] of owner * last taxes) public_funding

    governments.set_budget
    governments.education_calculation

    ;;Update our money and approval
    governments.update_approval
    governments.update_taxes
  ]
end

to governments.set_budget

  let edu_want item 1 one-of filter [ x -> item 0 x = "Education"] [ethics] of owner
  let welf_want item 1 one-of filter [x -> item 0 x = "Welfare"] [ethics] of owner

  let total_desire edu_want + welf_want

  set edu_want edu_want / total_desire
  set welf_want welf_want / total_desire

  set budget lput (list welf_want edu_want) budget

end

to governments.education_calculation
  let D last [desires] of owner

  let desire_percentages []
  foreach D [ x ->
    set desire_percentages lput (x / sum D) desire_percentages
  ]

  let tech []
  let i 0
  foreach desire_percentages [ x ->
    let progress (x * (item 1 last budget * last public_funding)) / tech_price
    set tech lput (item i last [technology_levels] of owner + progress) tech
    set i i + 1
  ]

  ask owner
  [
    set technology_levels lput tech technology_levels
  ]

end

;;Function which updates how much people approve of the government / political unrest
to governments.update_approval
  ;;we rate approval based on unemployment and taxes vs gdp and welfare

  let ethics_impact []

  let wel_value one-of filter [x -> item 0 x = "Welfare"] [ethics] of owner
  let wel_actual ((item 0 last budget * last public_funding) / last [population_over_time] of owner) * 100  ;;Decimal value
  Let wel_impact item 1 wel_value - wel_actual
  set wel_impact max (list min (list wel_impact 50) -50)

  set ethics_impact lput wel_impact ethics_impact

  let edu_value one-of filter [x -> item 0 x = "Education"] [ethics] of owner
  let edu_actual ((item 1 last budget * last public_funding) / last [population_over_time] of owner) * 100
  let edu_impact item 1 edu_value - edu_actual
  set edu_impact max (list min (list edu_impact 50) -50)

  set ethics_impact lput edu_impact ethics_impact

  let i 0
  while [i < length ethics_impact]
  [
    set ethics_impact replace-item i ethics_impact (item i ethics_impact / length ethics_impact)
    set i i + 1
  ]


  ;;For every percent of taxation, remove 2 percent of approval
  let taxes_impact min (list (max ( list (last taxes * 2) 0)) 50)

  ;;Total negative impact is the sum of these two
  let negative_impact (sum ethics_impact) + taxes_impact

  ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)


  ;;Using linear interpolation we find the impact of the rise of gdp and welfare on our approval
  ;;x0y0 = gdp_percentage min, impact min
  ;;x1y1 = gdp_percentage max, impact max


  let gdp_percentage 0
  if( year > 2)
  [
    let wealth [wealth_over_time] of owner

    let gdp_this_year last wealth - item (length wealth - 2) wealth
    let gdp_last_year item (length wealth - 2) wealth - item (length wealth - 3) wealth

    let last_gdp_dif  gdp_last_year - gdp_this_year

    If(last_gdp_dif != 0)
    [
      set gdp_percentage gdp_this_year / last_gdp_dif
    ]

  ]


  let yp -50 + ((50 + 50)/(0.5 + 0.5)) * (gdp_percentage + 0.5)
  let gdp_impact min (list (max (list yp -50)) 50)


  let positive_impact gdp_impact

   ;;We update our approval by deducting the impact of the negative from the impact of the positive.
   ;;Approval starts at 50 if neither positives nor negatives contribute, and has to stay between 100 and 0
  set approval lput min (list (max (list (50 + (positive_impact - negative_impact)) 0)) 100) approval
end

to governments.update_taxes
  set taxes lput last taxes taxes
end

;;Function which calculates population growth for a government
to-report pop_growth
  let population last [population_over_time] of owner
  ;;Births per woman

  ;;births per Woman = 7 - education - urbanization

  ;;Urbanization can be measured by seeing how large sectors 2 and 3 are compared to setor 1
  let rural 0
  let urban 0


  let i 0
  while [i < number_of_products]
  [
    ifelse( item 1 item i resource_list = 1)
    [
      ;;The item belongs to sector 1
      set rural rural + item i last [resources_over_time] of owner
    ]
    [
      set urban urban + item i last [resources_over_time] of owner
    ]
    set i i + 1
  ]


  let economy_difference min (list max (list ((rural - urban) / rural) -1) 1) ;;Urban = rural -> 0 ;;Urban > rural -> <0 ;;Rural > Urban -> >0


  ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)

  ;;Gives us a percentage impact between 0 and 33% on the total impact
  ;;Economy difference = 0 Worst, 33%
  ;;Economy difference = 100 best, 0%
  let urbanization max (list  min ( list  (50 - (50  * economy_difference)) 50 ) 0)

  ;;Finding impact of education
  ;;x0,y0 = min average education, max death-rate
  ;;X1,y1 = max average education, min death-rate
  ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)
  let yp 50 + ((0 - 50) / (1 - 0)) * ((((last public_funding * item 1 last budget)  + 1)  / (population + 1)) - 0)
  let education_impact min (list (max (list yp 0)) 50)

  let birthrate_factors education_impact + urbanization

  set birthrate_factors min (list (max (list birthrate_factors 0)) 100)

  let Max_births_per_woman (Max_crude_birthrate / 1000) / 2
  let Min_births_per_woman (Min_crude_birthrate / 1000) / 2

  ;;We find the final birthrate by checking how much the impact of the detrimental factors has removed us from the max birthrate
  let birthrate Max_births_per_woman - (((Max_births_per_woman - Min_births_per_woman) / 100) * birthrate_factors)

  let deathrate_factors []

  set yp 13 + ((1 - 13) / (Max_births_per_woman - Min_births_per_woman)) * (birthrate - Min_births_per_woman)
  let age_death_impact min (list (max (list yp 1)) 13) ;;Has to be between 1 and 13
  set deathrate_factors lput age_death_impact deathrate_factors


  ;;x0,y0 = min-gdp, max death-rate
  ;;x1,y1 = max-gdp, min death-rate
  set yp 13 + ((1 - 13) / ((first [wealth_over_time] of owner * 1000) - 0.1)) * (last [wealth_over_time] of owner - 0.1)
  let gpd_death_impact min (list (max (list yp 1)) 13)
  set deathrate_factors lput gpd_death_impact deathrate_factors

  let deaths population * ((mean deathrate_factors) / 1000) ;; deathrate is usually calculated by 1000, we have to divide by 1000 to get per person

  let women (population - deaths) / 2

  ;;Population growth = living women * births per woman
  let births women * birthrate

  ;;Migrations seems to mostly be based on GDP and population
  ;;min gdp , min migration
  ;;max gdp, max migration
  ;;yp = y0 + ((y1 - y0)/(x1 - x0)) * (x - x0)
  ;;let migration_factors []
  ;;let max_migration (population) / 100
  ;;let min_migration max_migration * -1

  ;;set yp  (min_migration + ((max_migration - min_migration) / ((initial_wealth * 1000) - 0.1)) * (last gdp - 0.1))
  ;;let gdp_migration_impact min (list (max (list yp min_migration)) max_migration)
  ;;set migration_factors lput gdp_migration_impact migration_factors

  ;;min population, min migration
  ;;Max population, max migration
  ;;set yp (min_migration + ((max_migration - min_migration ) / ((initial_population * 100) - 0)) * (last population - 0))
  ;;let population_migration_impact min (list (max (list yp min_migration))max_migration)
  ;;set migration_factors lput population_migration_impact migration_factors

  ;;let migration mean migration_factors

  report births - deaths

end
;;OUTPUT FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to finish
  let date nationsim.date_and_time
  let file (word "../csvfiles/nations_output_" date ".csv")

  csv:to-file file csv_list
end

to find_events

  ;;Find Severe increases / decreases in wealth and population
  ;;If the nation survived longer than the chosen interval for statistical readings
  if (year > years_for_statistics)
  [

    ;;Initialize the first check to start after a number of years equal to the interval chosen
    let i years_for_statistics

    ;;While the current year being checked is less than the number of years run
    while [i <= year]
    [

      ;;Create lists of wealth and population during the years in that interval
      let sublist_of_wealth (sublist wealth_over_time (i - years_for_statistics) i)
      let sublist_of_population (sublist population_over_time(i - years_for_statistics) i)

      ;;Sorted lists with the highest wealth and populations at the front, and the lowest wealth and populations at the back
      let sorted_wealth sort sublist_of_wealth
      let sorted_population sort sublist_of_population

      ;;Find the change in wealth between the highest and lowest values
      let difference (item (years_for_statistics - 1) sorted_wealth - item 0 sorted_wealth)

      ;;If the wealth has changed by more than 50% over the timeframe
      if ( difference > item 0 sublist_of_wealth / 2 )
      [
        ;;find the positions of the years with the most and least wealth
        let year_min (i - years_for_statistics) + position (min sublist_of_wealth) sublist_of_wealth
        let year_max (i - years_for_statistics) + position (max sublist_of_wealth) sublist_of_wealth

        ;;If the year with the lowest wealth is before, we have growth
        ifelse(year_min < year_max)
        [
          hatch-events 1 [
            set event_type "Economic Boom"
            set time list year_min year_max
            set owner myself
            set data difference
          ]
        ]
        ;;Else we have decline
        [
          hatch-events 1 [
            set event_type "Economic Crash"
            set time list year_min year_max
            set owner myself
            set data difference * -1
          ]
        ]

      ]

      ;;Now repeat the same process by finding the difference in population
      set difference (item (years_for_statistics - 1) sorted_population - item 0 sorted_population)

      ;;And if the population is significant enough, we have to go through and create an event
      if ( difference > item 0 sublist_of_population / 2)
      [
        ;;find the positions of the years with the highest and lowest values
        let year_min (i - years_for_statistics) + position (min sublist_of_population) sublist_of_population
        let year_max (i - years_for_statistics) + position (max sublist_of_population) sublist_of_population

        ;;If the year with the lowest population is first, we have growth
        ifelse(year_min < year_max)
        [
          hatch-events 1 [
            set event_type "Population Boom"
            set time list year_min year_max
            set owner myself
            set data difference
          ]
        ]
        ;;Else, we have decline
        [
          hatch-events 1 [
            set event_type "Population Crash"
            set time list year_min year_max
            set owner myself
            set data difference * -1
          ]
        ]
      ]

      ;;Update the year being checked
      set i i + years_for_statistics
      ]
    ]
end

;;Turns all information for an individual nation into a list of csv compliant data and adds it to the csv list for later transformation into a file
to csv.transform

  ;;Find all csv data for our home environment and add it to a list

  ;;For every neighbour, add all relevant relationship data to the list.
  ;;let neighbours (list (list"Neighbours"))
  ;;ask my-relations [
    ;;let info (list (list "Relation" self) (fput (word "Opinion of " myself " towards " self)  opinion_A_over_time) (fput (word "Opinion of " self " towards " myself) opinion_B_over_time)  (list "Struck deals" struck_deals) (list "Denied deals" denied_deals))
    ;;foreach info [subinfo -> set neighbours lput subinfo neighbours]
  ;;]

  ;;Create a main list which will contain all information
  let personal_information (list (list "Age" year))

  ;;Add all personal information into the csv_list
  foreach personal_information [info -> set csv_list lput info csv_list]

  ;;Add some final information about the wealth and population into the csv list
  set csv_list lput (fput "Wealth over time" wealth_over_time) csv_list
  set csv_list lput (fput "Population over time" population_over_time) csv_list
  set csv_list lput (fput "Available workforce over time" labor) csv_list

  ;;The values of the nation

  foreach ethics [x ->
    set csv_list lput x csv_list
  ]


  let i 0
  while [i < number_of_products]
  [
    let res (list (word item 0 item i resource_list " over time"))
    foreach resources_over_time [ x ->
      set res lput item i x res
    ]
    let tech (list (word "Technology levels " item 0 item i resource_list))
    foreach technology_levels [ x ->
      set tech lput item i x tech
    ]
     let des (list (word "Desire for " item 0 item i resource_list))
    foreach desires [ x ->
      set des lput item i x des
    ]
    let val (list (word "Value of " item 0 item i resource_list))
    foreach resource_values [ x ->
      set val lput item i x val
    ]

    set csv_list lput res csv_list
    set csv_list lput tech csv_list
    set csv_list lput des csv_list
    set csv_list lput val csv_list
    set i i + 1
  ]
end

to csv_init

  ;;Names of Columns
  let column_names (list "Random Seed" "Number of Nations" "Number of Resources" "Price of technological advancement" "Minimum crude birthrate" "Maximum crude birthrate")

  let ordered_nations sort nations
  foreach ordered_nations [x ->
    ask x [
      let info (list (word "Wealth at year 0 for " self) (word "Wealth at year 10 for " self) (word "Wealth at year 50 for " self) (word "Wealth at year 100 for " self)
        (word "Population at year 0 for " self) (word "Population at year 10 for " self) (word "Population at year 50 for " self) (word "Population at year 100 for " self)
        (word "Available labor at year 0 for " self) (word "Available labor at year 10 for " self) (word "Available labor at year 50 for " self) (word "Available labor at year 100 for " self))
      let i 0
      while [i < number_of_products]
      [
        let res_name item 0 item i resource_list
        let res_info (list (word res_name " at year 0 for " self) (word res_name " at year 10 for  " self) (word res_name " at year 50 for  " self) (word res_name " at year 100 for  " self)
          (word "Technology levels at year 0 for " res_name " for  " self) (word "Technology levels at year 10 for " res_name " for  " self) (word "Technology levels at year 50 for " res_name " for  " self) (word "Technology levels at year 100 for " res_name " for  " self)
          (word "Desire for " res_name " at year 0 for " self) (word "Desire for " res_name " at year 10 for " self) (word "Desire for " res_name " at year 50 for " self) (word "Desire for " res_name " at year 100 for " self)
          (word "Value of " res_name " at year 0 for " self) (word "Value of " res_name " at year 10 for " self) (word "Value of " res_name " at year 50 for " self) (word "Value of " res_name " at year 100 for " self))
        foreach res_info [ y ->
          set info lput y info
        ]
        set i i + 1
      ]
      foreach info [ y ->
        set column_names lput y column_names
      ]
      foreach ethics [ y ->
        set column_names lput (word item 0 y " of " self) column_names
      ]
      let gov_info []
      ask national_government [
        set gov_info ( list (word "Taxes at year 0 for " myself) (word "Taxes at year 10 for " myself) (word "Taxes at year 50 for " myself) (word "Taxes at year 100 for " myself)
          (word "Approval at year 0 for " myself) (word "Approval at year 10 for " myself) (word "Approval at year 50 for " myself) (word "Approval at year 100 for " myself)
          (word "public funding at year 0 for " myself) (word "public funding at year 10 for " myself) (word "public funding at year 50 for " myself) (word "public funding at year 100 for " myself)
          (word "Welfare Budget at year 0 for " myself) (word "Education Budget at year 0 for " myself) (word "Welfare Budget at year 10 for " myself) (word "Education Budget at year 10 for " myself)
       (word "Welfare Budget at year 50 for " myself) (word "Education Budget at year 50 for " myself) (word "Welfare Budget at year 100 for " myself) (word "Education Budget at year 100 for " myself) )
      ]
      foreach gov_info [ y ->
        set column_names lput y column_names
      ]
    ]
  ]

  let market_info []
  ask markets [

    let i 0
    while [ i < number_of_products]
    [
      let res_name item 0 item i resource_list
      let res_info (list (word res_name " sold at year 0 for " self) (word res_name " bought at year 0 for " self) (word res_name " sold at year 10 for " self) (word res_name " bought at year 10 for " self)
        (word res_name " sold at year 50 for " self) (word res_name " bought at year 50 for " self)  (word res_name " sold at year 100 for " self) (word res_name " bought at year 100 for " self)
        (word "Price of " res_name " at year 0 for " self)  (word "Price of " res_name " at year 10 for " self)  (word "Price of " res_name " at year 50 for " self)  (word "Price of " res_name " at year 100 for " self))

      foreach res_info [ x ->
        set market_info lput x market_info
      ]
      set i i + 1
    ]
  ]

  foreach market_info [ x ->
    set column_names lput x column_names
  ]

  set csv_list []
  set csv_list lput column_names csv_list

end

to csv_record_run

  let run_list (list seed)

  set run_list lput number_of_nations run_list
  set run_list lput number_of_products run_list
  set run_list lput tech_price run_list
  set run_list lput min_crude_birthrate run_list
  set run_list lput max_crude_birthrate run_list

  let nation_values csv_get_nation_values [0 10 50 100]

  foreach nation_values [ x ->
    set run_list lput x run_list
  ]

  let market_values csv_get_market_values [0 10 50 100]

  foreach market_values [x ->
    set run_list lput x run_list
  ]

  set csv_list lput run_list csv_list
end


to csv_events
  ;;For every event associated with the Nation, create an ordered timeline of all events and add them to the csv list in order
  let event_list (list (list "Events") )
  foreach sort-by [[x y]->  [item 0 time] of x < [item 0 time] of y] events with [owner = myself] [
    single_event ->
    ask single_event [
      let info (list ( list "Event" event_type) (fput "Between Years" time) )

      ;;If the word Economic shows up in the event type, it is either a crash or boom in wealth
      if( member? "Economic" event_type)
      [
        set info lput (list "Wealth change" data) info
      ]

      ;;If the word population shows up in the event type, it is either a crash or boom in population
      if ( member? "Population" event_type)
      [
        set info lput (list "Population change" data) info
      ]

      foreach info [subinfo -> set event_list lput subinfo event_list]
    ]
  ]
end

to-report csv_get_nation_values [index]
  let ilist []
  let ordered_nations sort nations
  foreach ordered_nations [ nat ->
    ask nat [
      foreach index [ x ->
        set ilist lput  item x wealth_over_time ilist
      ]
      foreach index [ x ->
        set ilist lput item x population_over_time ilist
      ]
      foreach index [ x ->
        set ilist lput item x labor ilist
      ]

      let i 0
      while [i < number_of_products]
      [

        foreach index [x ->
          set ilist lput item i item x resources_over_time ilist
        ]
        foreach index [x ->
          set ilist lput item i item x technology_levels ilist
        ]
        foreach index [x ->
          set ilist lput item i item x desires ilist
        ]
        foreach index [x ->
          set ilist lput item i item x resource_values ilist
        ]

        set i i + 1
      ]

      foreach ethics [ x ->
        set ilist lput item 1 x ilist
      ]

      ask national_government [
        set i 0
        foreach index [x ->
          set ilist lput item x taxes ilist
        ]
        foreach index [x ->
          set ilist lput item x approval ilist
        ]
        foreach index [x ->
          set ilist lput item x public_funding ilist
        ]
        foreach index [x ->
          set ilist lput item 0 item x budget ilist
          set ilist lput item 1 item x budget ilist
        ]


      ]
    ]
  ]
  report ilist
end

to-report csv_get_market_values [index]
  let ilist []

  let ordered_markets sort markets
  foreach ordered_markets [ x ->
    ask x [
      let i 0
      while [i < number_of_products]
      [
          let sold_list []
          let bought_list []
        foreach index [ y ->
          let j 0
          while [j <= y]
          [
            set sold_list lput item 0 item i item j international_resource_log sold_list
            set bought_list lput item 1 item i item j international_resource_log bought_list
            set j j + 1
          ]

          set ilist lput (sum sold_list / length sold_list) ilist
          set ilist lput (sum bought_list / length bought_list) ilist
        ]
        foreach index [ y ->
          set ilist lput item i item y international_prices ilist
        ]
        set i i + 1
      ]
    ]
  ]

  report ilist
end

;;HELPER FUNCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

to-report nationsim.date_and_time
  let date date-and-time

  let pos position "." date
  let pos2 position " " date
  let discard substring date (pos - 3) (pos2 + 1)
  set date remove discard date
  set date remove "PM" date
  set date remove "AM" date
  while [(position " " date) != false]
  [
    set date nationsim.string_replace date " " "_"
  ]
  while [(position ":" date) != false]
  [
    set date nationsim.string_replace date ":" "."
  ]
  while [(position "-" date) != false]
  [
    set date nationsim.string_replace date "-" "."
  ]


report date
end

;;FILE FUNCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to nationsim.get_nation_variables

  file-open source_file


  ;;Loading all global values
  set seed nationsim.read
  set reruns nationsim.read
  set number_of_nations nationsim.read
  set number_of_products nationsim.read
  set years_for_statistics nationsim.read
  set tech_price nationsim.read
  set Min_crude_birthrate nationsim.read
  set Max_crude_birthrate nationsim.read
  set resource_list nationsim.read

  let i 0
  while [i < number_of_nations]
  [
    create-nations 1 [
      nations.file_setup
      hatch-governments 1 [
        set owner myself
        ask owner [
          set national_government myself
        ]
        governments.file_setup
      ]
    ]
    set i i + 1
  ]

   Nationsim.get_commands

  file-close

end

to nationsim.get_commands
  set commands []
  let index 0
  while [file-at-end? = false]
  [
    let date nationsim.read
    let code nationsim.read
    let pos position "\"" code
    let command []

    ifelse( pos != false)
    [
      let excludes []
      let sub-code code
      let last-pos 0

      while [pos != false]
      [

        set excludes lput (pos + last-pos) excludes

        set last-pos last-pos + pos + 1 ;;Gotta account for the fact that \" is 2 letters
        set sub-code substring code (last-pos) (length code - 1)
        set pos position "\"" sub-code
      ]

      let inter_strings []
      let sub_code []
      let i 0
      while [i < length excludes - 1]
      [
        set inter_strings lput substring code (item i excludes + 1)  item (i + 1) excludes inter_strings
        set sub_code lput substring code (item i excludes) (item (i + 1) excludes + 1) sub_code
        set i i + 2
      ]

      set i 0
      while [i < length sub_code]
      [
        set code nationsim.string_replace code (item i sub_code) (word " item " i " item 2 item " index " commands ")
        set i i + 1
      ]

      set command (list date code inter_strings)
    ]
    [
      set command (list date code [])
    ]

    set index index + 1

    set commands lput command commands
  ]
  set commands sort-by [ [x y] -> item 0 x < item 0 y] commands
end

to nationsim.execute_commands
  let current-commands filter [ x -> item 0 x = year] commands

  foreach current-commands [ x ->
   run item 1 x
  ]
end

;;Functionally equivalent to file-read, but ignores comments in format "#" Comment "#" and empty lines
;;Also checks for lines with the "~" signifier at the start and if it exists reports the entire line.
;;If instead the ">" signifier is found, it reads the line as a reporter and reports the output.
to-report nationsim.read

  let f file-read
  ;;Skip any comments at the start of file
  ifelse (f = "#")
  [
    set f file-read

    while [f != "#"]
    [
      set f file-read

    ]
    report nationsim.read
  ]
  [
    ifelse (f = "~")
    [
      set f file-read-line
      report f
    ]
    [
      ifelse (f = ">")
      [
        set f file-read-line
        set f run-result f
        report f
      ]
      [
         ifelse (f = "|")
        [
          let pred file-read
          let values file-read

          ifelse(run-result pred = true)
          [

            if( position "list " item 0 values != false)
            [
              let result remove "list " item 0 values
              report (list run-result result)
            ]
            report run-result item 0 values
          ]
          [

            report item 1 values
          ]
        ]
        [
           ifelse (f = "z")
          [
            let pred file-read
            let values file-read
            let default file-read
            let mutator run-result file-read
            let counters file-read

            ifelse (run-result pred = true)
            [
              let i 1
              while [i < length counters]
              [

                if(mutator > item (i - 1) counters and  mutator <= item i counters )
                [
                  ifelse(length values = 1)
                  [
                    let current_value item (i - 1) last values
                    let new_value replace-item (i - 1) last values ( current_value + (current_value * (mutator - item (i - 1) counters)))
                    set values replace-item (length values - 1) values new_value
                  ]
                  [
                    let current_value item 1 (item (i - 1) values)
                    let new_value replace-item 1 (item (i - 1) values) (current_value + (current_value * (mutator - item (i - 1) counters)))
                    set values replace-item (i - 1) values new_value
                  ]
                  report values
                ]
                set i i + 1
              ]
            ]
            [
              report default
            ]
          ]
          [
            report f
          ]
        ]
      ]
    ]
  ]

end

;;Each new list in csv_list is a new row
;;Each item inside that list is a new column
;;Each row is a variable, each column is the value at that year
to nationsim.csv_input

  ;;Number of Nations
  set csv_list lput (list "Number of Nations" number_of_nations) csv_list
  ;;Number of Resources
  set csv_list lput (list "Number of Resources" number_of_products) csv_list

  set csv_list lput (list "Years for Statistics" years_for_statistics) csv_list

  set csv_list lput (list "Price of technology" tech_price) csv_list

end

to-report nationsim.string_replace [string target new_value]

  let pos position target string
  ifelse(length target = 1)
  [
    set string remove-item pos string
  ]
  [
    set string remove target string
  ]
    set string insert-item pos string new_value

  report string
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
1
1
1
ticks
30.0

BUTTON
6
10
69
43
Go
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
75
10
139
43
Setup
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
6
48
69
81
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
7
85
202
118
Nation_count
Nation_count
2
10
2.0
1
1
Nations
HORIZONTAL

MONITOR
589
10
646
55
Years
year
0
1
11

SLIDER
6
124
205
157
number_of_resources
number_of_resources
2
11
6.0
1
1
Products
HORIZONTAL

INPUTBOX
144
12
209
72
runtime
100.0
1
0
Number

SLIDER
7
163
204
196
initial_population_max
initial_population_max
100
10000
10000.0
100
1
People
HORIZONTAL

SLIDER
7
203
204
236
initial_population_min
initial_population_min
100
1000
1000.0
100
1
people
HORIZONTAL

SWITCH
8
406
111
439
debug
debug
1
1
-1000

SLIDER
8
242
200
275
initial_wealth
initial_wealth
10
10000
1030.0
10
1
$
HORIZONTAL

SLIDER
8
283
200
316
initial_unemployment
initial_unemployment
0
100
6.0
1
1
%
HORIZONTAL

SLIDER
9
323
202
356
Maximum_crude_birthrate
Maximum_crude_birthrate
0
50
27.0
1
1
bpw
HORIZONTAL

SLIDER
8
364
205
397
Minimum_crude_birthrate
Minimum_crude_birthrate
0
50
14.0
1
1
bpw
HORIZONTAL

PLOT
653
11
1265
195
Resource change
Years
Resource Value
0.0
100.0
-100.0
100.0
true
true
"" ""
PENS
"Wood" 1.0 0 -2674135 true "" "let value 0\nask markets\n[\nlet resource last item 0 international_resource_storage\nset value item 0 resource - item 1 resource\n]\n\nplot value"
"Stone" 1.0 0 -7500403 true "" "let value 0\nask markets\n[\nlet resource last item 1 international_resource_storage\nset value item 0 resource - item 1 resource\n]\n\nplot value"
"Iron" 1.0 0 -12895429 true "" "let value 0\nask markets\n[\nlet resource last item 2 international_resource_storage\nset value item 0 resource - item 1 resource\n]\n\nplot value"
"Copper" 1.0 0 -6995700 true "" "let value 0\nask markets\n[\nlet resource last item 3 international_resource_storage\nset value item 0 resource - item 1 resource\n]\n\nplot value"

PLOT
650
197
1264
393
National wealth
Years
$$$ 
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Rich" 1.0 0 -16777216 true "" "let value 0\n\nask one-of nations with [name = \"Germany\"] [\nset value last wealth_over_time\n]\n\nplot value"
"Poor" 1.0 0 -7500403 true "" "let value 0\n\nask one-of nations with [name = \"France\"] [\nset value last wealth_over_time\n]\n\nplot value"

INPUTBOX
7
446
191
506
Source_File
NIL
1
0
String

MONITOR
532
10
589
55
NIL
runs
17
1
11

INPUTBOX
9
512
164
572
Times_to_run_the_simulation
1000.0
1
0
Number

INPUTBOX
9
577
164
637
Length_of_statistics_intervals
10.0
1
0
Number

SLIDER
9
639
196
672
Price_of_technology
Price_of_technology
100
10000
1000.0
100
1
$
HORIZONTAL

PLOT
1271
11
1820
193
Nation Population
Year
Population
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Rich" 1.0 0 -16777216 true "" "let pop 0\n\nask one-of nations with [name = \"Germany\"][\nset pop last population_over_time\n]\n\nplot pop"
"Poor" 1.0 0 -7500403 true "" "let pop 0\n\nask one-of nations with [name = \"France\"] [\nset pop last population_over_time\n]\n\nplot pop"

PLOT
1270
201
1821
351
Government Approval
Years
Approval
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Rich" 1.0 0 -16777216 true "" "let app 0\nask one-of governments with [[name] of owner = \"Germany\"]\n[\nset app last approval\n] \n\nplot app"
"Poor" 1.0 0 -7500403 true "" "let app 0\nask one-of governments with [[name] of owner = \"France\"]\n[\nset app last approval\n] \n\nplot app"

BUTTON
76
49
139
82
NIL
clear\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
651
399
1265
549
National resources
Years
Resource_count in log 10
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Wood" 1.0 0 -2674135 true "" "let value 0\nask nations [\nset value item 0 last resources_over_time\n]\nplot log value 10"
"Stone" 1.0 0 -7500403 true "" "let value 0\nask nations [\nset value item 1 last resources_over_time\n]\nplot log value 10"
"Iron" 1.0 0 -16777216 true "" "let value 0\nask nations [\nset value item 2 last resources_over_time\n]\nplot log value 10"
"Copper" 1.0 0 -955883 true "" "let value 0\nask nations [\nset value item 3 last resources_over_time\n]\nplot log value 10"

PLOT
1271
357
1821
507
Market_prices
years
$
0.0
100.0
0.0
1.0
true
true
"" ""
PENS
"Wood" 1.0 0 -2674135 true "" "let val 0\nask markets [\nset val item 0 last international_prices\n]\nplot val"
"Stone" 1.0 0 -7500403 true "" "let val 0\nask markets [\nset val item 1 last international_prices\n]\nplot val"
"Iron" 1.0 0 -14737633 true "" "let val 0\nask markets [\nset val item 2 last international_prices\n]\nplot val"
"Copper" 1.0 0 -6995700 true "" "let val 0\nask markets [\nset val item 3 last international_prices\n]\nplot val"

PLOT
1270
514
1823
664
National_prices
Years
$
0.0
100.0
0.0
1.0
true
true
"" ""
PENS
"Wood" 1.0 0 -2674135 true "" "let value 0\nif(count nations > 0)\n[\nask nations [\nset value value + item 0 last resource_values\n]\n\nset value value / count nations\n]\nplot value"
"Stone" 1.0 0 -7500403 true "" "let value 0\nif(count nations > 0)\n[\nask nations [\nset value value + item 1 last resource_values\n]\n\nset value value / count nations\n]\nplot value"
"Iron" 1.0 0 -16777216 true "" "let value 0\nif(count nations > 0)\n[\nask nations [\nset value value + item 2 last resource_values\n]\n\nset value value / count nations\n]\nplot value"
"Copper" 1.0 0 -955883 true "" "let value 0\nif(count nations > 0)\n[\nask nations [\nset value value + item 3 last resource_values\n]\n\nset value value / count nations\n]\nplot value"

PLOT
652
556
1265
778
Trades
Years
Trades
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Nation 1 successes" 1.0 0 -16777216 true "" "let value 0\nask one-of nations with [name = \"Germany\"]\n[\n  set value item 0 last trades\n]\n\nplot value"
"Nation 1 Failures" 1.0 0 -7500403 true "" "let value 0\nask one-of nations with [name = \"Germany\"]\n[\n  set value item 1 last trades\n]\n\nplot value"
"Nation 1 No resources" 1.0 0 -2674135 true "" "let value 0\nask one-of nations with [name = \"Germany\"]\n[\n  set value item 2 last trades\n]\n\nplot value"
"Nation 1 No Labor" 1.0 0 -955883 true "" "let value 0\nask one-of nations with [name = \"Germany\"]\n[\n  set value item 3 last trades\n]\n\nplot value"
"Nation 2 Successes" 1.0 0 -6459832 true "" "let value 0\nask one-of nations with [name = \"France\"]\n[\n  set value item 0 last trades\n]\n\nplot value"
"Nation 2 Failures" 1.0 0 -1184463 true "" "let value 0\nask one-of nations with [name = \"France\"]\n[\n  set value item 1 last trades\n]\n\nplot value"
"Nation 2 No resources" 1.0 0 -10899396 true "" "let value 0\nask one-of nations with [name = \"France\"]\n[\n  set value item 2 last trades\n]\n\nplot value"
"Nation2 No labor" 1.0 0 -13840069 true "" "let value 0\nask one-of nations with [name = \"France\"]\n[\n  set value item 3 last trades\n]\n\nplot value"

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
