extensions [ csv ]

breed [nations nation]
undirected-link-breed [relations relation]
breed [environments environment]
breed [deals deal]
breed [events event]

nations-own [
  ;;The wealth of the nation at every timestep
  wealth_over_time

  ;;The population of the nation at every timestep
  population_over_time

  ;;The environment in which the nation exists
  Agentset home_environment
]

relations-own [
  ;;Opinion of nation 1 towards nation 2 at each timestep
  opinion_A_over_time

  ;;Opinion of nation 2 towards nation 1 at each timestep
  opinion_B_over_time

  ;;Any deals that have not yet been accepted or rejected this timestep
  pending_deals

  ;;Total number of deals made
  struck_deals

  ;;Total number of deals denied
  denied_deals
]

deals-own[
  ;;The Relation-class that is the parent of this deal
  owner_relation

  ;;The nation that suggested this deal
  owner_nation

  ;;Whether the deal is about the purchasing or selling of a commodity
  sale

  ;;The amount of the commodity being traded [value, budget]
  transaction
]

environments-own[

  ;;How much money the environment generates per timestep
  wealth

  ;;How much the number of people the nation can support grows per timestep
  fertility

  ;;The nation that this environment belongs to
  parent
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
  year ;;current year
  csv_list ;; The list that will be printed to a csv-
]

;;Sets up the simulation, does common maintenance like resetting parameters, and makes a number of nations and sets those up
to setup
  clear-all
  set year 0
  set csv_list []
  create-nations 5[
    nations.setup
  ]
  ask nations[
    nations.find_neighbours
  ]
  reset-ticks
end

;;Runs 1/timestep and updates relevant components of simulation
to go
  ifelse(year < runtime)
  [

    set year (year + 1)
    ;;show (word "Year: " year)
    ask nations[
      nations.update
    ]

    ;;Checks and updates for non-required components of simulation
    if environment_changes
    [
      ask environments [
        environments.update
      ]
    ]
    if trading
    [
      ask relations [
        relations.update_deals
      ]
    ]
    tick
  ]
  [
    finish
  ]

end

;;Does all setup for a nation. Runs only once per nation at the start of the simulation
to nations.setup
  hatch-environments 1 [
    ;;Set wealth and fertility to be between 1 and Max
    set wealth  (random(max_wealth -  1) + 1)
    set fertility (random(max_fertility - 1) + 1)

    ;;Make sure the environments parent is this nation
    set parent myself

    ;;Make sure this nations home_environment is this environment
    ask parent [
      set home_environment myself
    ]
  ]

  ;;Initialize wealth and population lists with initial values
  set wealth_over_time (list [wealth] of home_environment )
  set population_over_time  (list starting_population)
end

;;Setup function for nations. Finds all other nations and adds them to a list, then sets up relation-classes with all of them
to nations.find_neighbours
  ;;Adds all other nations into the neighbours list.
  let neighbours other nations with [distance myself < neighbour_distance]

  ask neighbours [
    ;;If we do not have a link to the other nation, we need to make one. If the other nation has run before this one, we will already have a link to it
    if not (relation-neighbor? myself) [
      ;;Create a relation link between this nation and the applicable neighbour, and initialize it's values
      create-relation-with myself [
        set opinion_A_over_time (list starting_opinion)
        set opinion_B_over_time (list starting_opinion)
        set pending_deals nobody
        set struck_deals 0
        set denied_deals 0
      ]
    ]
  ]
end

;;Runs once per timestep and updates parameters of natio¨n
to nations.update

  ;;If the nation has a population of zero (or below)
  ifelse  (item (year - 1) population_over_time) <= 0
  [
    ;;Add the nations data and events to the csv-list
    csv.transform

    ;;Delete environment
    ask home_environment [
      die
    ]

    ;;Delete Nation
    die
  ]
  ;;If the nation has a non-zero or below population
  [
    ;;Update the home_environment of the nation
    nations.update_environments

    ;;If we are using the non-essential trading submodule, update our relations
    if(trading)
    [
      nations.update_relations
    ]
  ]
end

;;Function which updates every relation the nation has and makes trade deals
to nations.update_relations

  ;;If wealth is higher than required, wealth can be traded with other nations with high fertility and low wealth to increase fertility
  let budget round(( ((item (year) wealth_over_time) * wealth_impact) - (item (year) population_over_time) ) / wealth_impact)

  ;;How much more fertility could the nation potentially have
  let missing_fertility max_fertility - [fertility] of home_environment


  ;;If the trade-budget is not in the minus, we can potentially buy something
  ifelse budget > 0
  [
    ;; If our fertility is not maxed out and we have neighbors
    if missing_fertility > 0  AND  count relation-neighbors > 0
    [

      ;;The more fertility we are missing, the more we want extra fertility
      ;;Between 0.5 and 2
      let demand max list (missing_fertility / (max_fertility / 2)) 0.5

      ;;How many people the nation can produce per year. Approximation of a growth function
      let growth_rate round(((item year population_over_time)/ 2) * ([fertility] of home_environment / 10) )

      ;;How many years worth of growth our budget represents
      let years_worth 0

      ;;If we can produce more than 0 people this year, we calculate the value if a single point of fertility for the nation this year
      ifelse(growth_rate > 0)
      [
        set years_worth budget / growth_rate
      ]
      ;;If we cannot, we set the value to be 100
      [
        set years_worth 100
      ]
      ;;if years_wort = 1 multiplier should be 1
      ;;If years_worth < 1 multiplier should be above 1
      ;;If years_worth > 1 mutliplier should be below 1
      ;;But 1/years_worth sinks too fast
      ;;As years_worth approaches 0, supply should approach 2
      ;;As years_worth approaches infinity, supply should approach 0.5
      let supply max list (20 / 10 + (years_worth * 10)) 0.5

      ;;The value of a single point of fertility to this nation
      let value_of_fertility round(base_value_of_fertility * supply * demand)

      ;;If the value of fertility exceeds the budget, set it to the budget
      if value_of_fertility > budget [
        set value_of_fertility budget
      ]

      ;;While we have money, offer deals for fertility points

      ;;For each neighbour we have a relation to
      let number_of_buyers (count nations) - 1

      ;;If we can make less deals than we have potential buyers we set the maximum number of buyers equal to the amount of deals we can make
      if(round(budget / value_of_fertility) < number_of_buyers)
      [
        set number_of_buyers round(budget / value_of_fertility)
      ]

      ;;Check to make sure we do no make more deals than we need fertility
      if(number_of_buyers > missing_fertility)
      [
        set number_of_buyers missing_fertility
      ]

      ;;Set the maximum price we can pay for any one fertility
      let remaining_budget budget - (number_of_buyers * value_of_fertility)
      let max_price value_of_fertility + (remaining_budget / number_of_buyers)

      ;;Picks a number of nations equal to "number_of_buyers" from the nations we have a relation to with the least money.
      let buyers min-n-of number_of_buyers relation-neighbors [item (year - 1) wealth_over_time]

      ;;Ask each of those nations to make a deal
      ask buyers
      [
        ;;Make sure we can access this nation from two layers down
        let owning_relation relation-with myself
        let owning_nation myself

        ;;Create a deal which has an owner equal to the relation this buyer has with the selling nation
        hatch-deals 1 [
          set owner_nation owning_nation
          set owner_relation owning_relation
          set sale "Buy"
          set transaction list value_of_fertility max_price
        ]
      ]
    ]
  ]
  ;;If the trade budget is in the minus, we need to sell something
  [

    ;;As long as we do have fertility remaining and have neighbors
    if [fertility] of home_environment > 0   AND count relation-neighbors > 0
    [
      ;;How much money we want for our fertility
      ;;MAX = 2, MIN = 0.5
      let supply 0

      ;;If missing fertility is 0, we set supply multiplier to it's highest value
      ifelse(missing_fertility <= 0)
      [
        set supply 2;
      ]
      ;;Else, we figure out how badly we want to sell, with 0.5 times max_fertility giving us the base 1 value.
      [
        set supply ((max_fertility / 2) / (missing_fertility))
      ]

      ;;Growth rate is how many people we can grow with over the course of a year
      let growth_rate round(((item year population_over_time) / 2) * ([fertility] of home_environment / 10) )

      ;;How badly we need to buy fertility to sustain our growth
      ;;Min 0.5, Max 2
      let demand 0

      ;;If we still are growing each year
      ifelse(growth_rate > 0)
      [
        ;;Create a multiplier between 2 and 0.5 based on how much we are still growing
        ;;How much we grew last year
        let previous_growth item year population_over_time - item (year - 1) population_over_time

        ;;Comparing growth rates
        ifelse(growth_rate > previous_growth)
        [
          ;;If we are growing more than last year still, set demand to the minimum
          set demand 0.5
        ]
        [
          ;;If we are growing less than last year, set demand to be equal to the factor by which we reduced our growth.
          ;;If growth is halved compared to the previous year, we reach the minimum multiplier of 0.5
          set demand max list (growth_rate / previous_growth) 0.5
        ]
      ]
      ;;If we are facing a population crisis
      [
        ;;Set demand to it's highest value
        set demand 2
      ]

      ;;The value of fertility is calculated by it's baseline, and supply and demand
      ;;Approximation of value curve
      let value_of_fertility round(base_value_of_fertility * supply * demand)

      ;;Find the nation with the most money out of all nations that do not have the maximum number of fertility
      let buyer max-one-of relation-neighbors with [[fertility] of [home_environment] of self < max_fertility ] [item (year - 1) [wealth_over_time] of self]

      ;;If such a nation exists
      if(buyer != nobody)
      [
        ;;Ensure we can still get the relation in the hatch statement
        let owning_relation relation-with buyer

        ;;Create and initialize a deal for 1 fertility with the potential buyer
        hatch-deals 1 [
          set owner_nation myself
          set owner_relation owning_relation
          set sale "Sell"
          set transaction list value_of_fertility 0
        ]
      ]
    ]
  ]
end


to nations.update_environments

  ;;Update Environments:
  ;;If Population grows larger than what the wealth can support, we loose growth
  ;;Likewise, events such as famine and drought impact fertility and Wealth
  ;;Growth is based on size of population and fertility

  ;;Grow wealth and fertility by the environments wealth
  let p_wealth [wealth] of home_environment
  let p_fertility [fertility] of home_environment

  ;;Gather current values for population, wealth, and maximum population given current wealth
  let current_population  item (year - 1) population_over_time
  let current_wealth  item (year - 1) wealth_over_time
  let max_support  current_wealth * wealth_impact

  ;;If the current population can be supported
  ifelse (current_population <= max_support)
  [
    ;;Grow the population. Approximate growth function
    let pop_growth round( (current_population / 2) * (p_fertility / 10) )

    ;;Update current value for population at this timestamp
    set population_over_time lput (current_population + pop_growth) population_over_time
  ]
  ;;If the population is higher than what can be supported by the nations wealth
  [
    ;;We reduce the population by a fraction of the negative amount of available support
    let decrease  round ( (current_population - max_support) * 0.1)

    ;;If the decrease is too low we fix that
    if decrease < 1 [set decrease 1]

    ;;If this decrease would put population below 0, we put it to 0
    ifelse current_population - decrease < 0
    [
      set population_over_time lput 0 population_over_time
    ]
    ;;Otherwise, we decrease population accordingly
    [
      set population_over_time lput (current_population - decrease) population_over_time
    ]
  ]

  ;;The nation gains wealth equal to the wealth of the environment each year
  set wealth_over_time lput (current_wealth + p_wealth) wealth_over_time
end

;;Go through list of owned deals and either accept or reject them
to relations.update_deals

  ;;All deals offering to buy (should never be above 1)
  let request ( deals with [owner_relation = myself AND sale = "Buy"] )

  ;;All deals offering to sell (should never be above 1)
  let offer ( deals with [owner_relation = myself AND sale = "Sell"] )

  ;;If we have an offer and a request
  ifelse( count offer > 0 AND count request > 0)
  [
    ;;Check the difference in desired value for the fertility being traded
    let difference abs (item 0 [item 0 transaction] of request -  item 0 [item 0 transaction] of offer)

    ;;Check the opinions that the two nations have of eachother
    let opinion_impact item (year - 1) opinion_A_over_time + item (year - 1) opinion_B_over_time

    ;;Reduce the difference accordingly to make them more likely to ignore the split
    let aversion difference - (opinion_impact * opinion_weight)

    ;; If the buyer is willing to pay more than the seller is requesting or the total difference is less or equal to 0, we automatically succeed the transaction.
    ifelse( difference <= 0 OR (item 0 [item 0 transaction] of request > item 0  [item 0 transaction] of offer) )
    [
      ;;Increase national oppinions of one another
      set opinion_A_over_time lput (item (year - 1) opinion_A_over_time + 1) opinion_A_over_time
      set opinion_B_over_time lput (item (year - 1) opinion_B_over_time + 1) opinion_B_over_time

      ;;Ask both seller and buyer to update their status in accordance with the deal
      ask item 0 [owner_nation] of request [
        set wealth_over_time replace-item (year) wealth_over_time  (item (year) wealth_over_time - item 0 [item 0 transaction] of request )
        ask home_environment [
          set fertility fertility + 1
        ]
      ]

      ask item 0 [owner_nation] of offer [
        set wealth_over_time replace-item (year) wealth_over_time  (item (year) wealth_over_time + item 0 [ item 0 transaction] of request )
        ask home_environment [
          set fertility fertility - 1
        ]
      ]

      ;;Increase struck deals by 1
      set struck_deals struck_deals + 1
    ]
    ;;If the difference is larger than 0, the nations bargain for the right price.
    [
      ;;If the difference is less than 10% of both asking and offering price, and that is within the max that the requesting nation CAN pay, the nations split the difference into a compromise where both sides meet in the middle.
      ifelse( aversion / item 0 [item 0 transaction] of request < 0.1 AND aversion / item 0 [item 0 transaction] of offer < 0.1 AND (item 0 [ item 0 transaction] of request + (difference / 2)) < item 0 [ item 1 transaction] of request)
      [
        ;;Update oppinions to be more positive
        set opinion_A_over_time lput (item (year - 1) opinion_A_over_time + 1) opinion_A_over_time
        set opinion_B_over_time lput (item (year - 1) opinion_B_over_time + 1) opinion_B_over_time

        ;;calculate compromise markup/down
        let compromise item 0 [item 0 transaction] of request +  (difference / 2) ;;Compormise on price in the middle

        ;;Update both nations statuses accordingly
        ask item 0 [owner_nation] of request [
          set wealth_over_time replace-item (year) wealth_over_time  (item (year) wealth_over_time - compromise )
          ask home_environment [
            set fertility fertility + 1
          ]
        ]

        ask item 0 [owner_nation] of offer [
          set wealth_over_time replace-item (year) wealth_over_time  (item (year) wealth_over_time + compromise )
          ask home_environment [
            set fertility fertility - 1
          ]
        ]

        ;;Update number of deals struck
        set struck_deals struck_deals + 1
      ]
      ;;The difference is too large for the nations to come to an agreement
      [
        ;;Update oppinions to be more negative
        set opinion_A_over_time lput (item (year - 1) opinion_A_over_time - 1) opinion_A_over_time
        set opinion_B_over_time lput (item (year - 1) opinion_B_over_time - 1) opinion_B_over_time

        ;;Increase denied deals by 1
        set denied_deals denied_deals + 1
      ]

    ]
  ]
  [
    ;;If nothing is to do, just update the current timestep for oppinions for both nations
    set opinion_A_over_time lput (item (year - 1) opinion_A_over_time ) opinion_A_over_time
    set opinion_B_over_time lput (item (year - 1) opinion_B_over_time ) opinion_B_over_time

  ]
    ;;At the end of the transaction phase, delete all pending deals
    ask deals with  [owner_relation = myself] [ die ]
end

;;Controls random changes in the environment which effect nation growth
to environments.update
  ;;Create a random number
  let random_event random(1000)

  ;;1% chance for a negative event
  if random_event < 10 ;;Negative event
  [
    ;;Odds reduce the wealth
    ifelse (random_event mod 2 = 0)
    [
      if (wealth > 0)
      [
        set wealth wealth - 1
      ]
    ]
    ;;Evens reduce fertility
    [
      if (fertility > 0)
      [
        set fertility fertility - 1
      ]
    ]
  ]
  ;;1% chance for a positive event
  if random_event > 990 ;;Positive event
  [
    ;;Odds increase wealth
    ifelse (random_event mod 2 = 0)
    [
      if wealth < max_wealth
      [
        set wealth wealth + 1
      ]
    ]
    ;;Evens increase fertility
    [
      if fertility < max_fertility
      [
        set fertility fertility + 1
      ]
    ]
  ]
end

;;Last thing to run, asks nations to finish up and creates the csv file with results
to finish
  let file "nations_data.csv"

  ask nations [
    find_events
    csv.transform
  ]
  csv:to-file file csv_list
end

;;Finds and creates all events that happened over the lifespan of a nation
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
  let home_env (list (list "Home Environment" home_environment) (list "Fertility" [fertility] of home_environment) (list "Wealth" [wealth] of home_environment))

  ;;For every neighbour, add all relevant relationship data to the list.
  let neighbours (list (list"Neighbours"))
  ask my-relations [
    let info (list (list "Relation" self) (fput (word "Opinion of " myself " towards " self)  opinion_A_over_time) (fput (word "Opinion of " self " towards " myself) opinion_B_over_time)  (list "Struck deals" struck_deals) (list "Denied deals" denied_deals))
    foreach info [subinfo -> set neighbours lput subinfo neighbours]
  ]

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

  ;;Create a main list which will contain all information
  let personal_information (list (list "Name" self) (list "Age" year))

  ;;Add all information of the neighbours, environment, and events into the main list
  foreach neighbours [info -> set personal_information lput info personal_information]
  foreach home_env [info -> set personal_information lput info personal_information]
  foreach event_list [info -> set personal_information lput info personal_information]

  ;;Add all personal information into the csv_list
  foreach personal_information [info -> set csv_list lput info csv_list]

  ;;Add some final information about the wealth and population into the csv list
  set csv_list lput (fput "Wealth over time" wealth_over_time) csv_list
  set csv_list lput (fput "Population over time" population_over_time) csv_list

end
@#$#@#$#@
GRAPHICS-WINDOW
318
24
943
650
-1
-1
18.7
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
37
30
100
63
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
106
31
169
64
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
17
79
189
112
max_wealth
max_wealth
1
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
17
121
189
154
max_fertility
max_fertility
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
16
172
188
205
starting_opinion
starting_opinion
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
15
222
187
255
starting_population
starting_population
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
15
267
187
300
wealth_impact
wealth_impact
1
50
20.0
1
1
NIL
HORIZONTAL

MONITOR
318
24
375
69
Year
year
17
1
11

PLOT
948
24
1833
174
Populations of Nations
Year
Population
0.0
100.0
0.0
100000.0
true
true
"" ""
PENS
"Nation 0" 1.0 0 -16777216 true "" "let pop 0\nif nation 0 != nobody \n[\nask nation 0 [\n set pop item year population_over_time \n]\n]\nplot pop"
"Nation 1" 1.0 0 -7500403 true "" "let pop 0\nif nation 1 != nobody \n[\nask nation 1 [\n set pop item year population_over_time \n]\n]\nplot pop"
"Nation 2" 1.0 0 -2674135 true "" "let pop 0\nif nation 2 != nobody \n[\nask nation 2 [\n set pop item year population_over_time \n]\n]\nplot pop"
"Nation 3" 1.0 0 -955883 true "" "let pop 0\nif nation 3 != nobody \n[\nask nation 3 [\n set pop item year population_over_time \n]\n]\nplot pop"
"Nation 4" 1.0 0 -6459832 true "" "let pop 0\nif nation 4 != nobody \n[\nask nation 4 [\n set pop item year population_over_time \n]\n]\nplot pop"

BUTTON
173
31
236
64
go
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

PLOT
948
335
1832
485
Fertility of environments
Year
Fertility
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Environment 0" 1.0 0 -16777216 true "" "let fert  0\nlet env []\nif nation 0 != nobody \n[\nask nation 0 [\n set env home_environment\n]\nask env [\n set fert fertility\n]\n]\nplot fert"
"Environment 1" 1.0 0 -7500403 true "" "let fert  0\nlet env []\nif nation 1 != nobody \n[\nask nation 1 [\n set env home_environment\n]\nask env [\n set fert fertility\n]\n]\nplot fert"
"Environment 2" 1.0 0 -2674135 true "" "let fert  0\nlet env []\nif nation 2 != nobody \n[\nask nation 2 [\n set env home_environment\n]\nask env [\n set fert fertility\n]\n]\nplot fert"
"Environment 3" 1.0 0 -955883 true "" "let fert  0\nlet env []\nif nation 3 != nobody \n[\nask nation 3 [\n set env home_environment\n]\nask env [\n set fert fertility\n]\n]\nplot fert"
"Environment 4" 1.0 0 -6459832 true "" "let fert  0\nlet env []\nif nation 4 != nobody \n[\nask nation 4 [\n set env home_environment\n]\nask env [\n set fert fertility\n]\n]\nplot fert"

PLOT
949
492
1833
642
Wealth of Environments
Wealth
Year
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Environment 0" 1.0 0 -16777216 true "" "let wel  0\nlet env []\nif nation 0 != nobody \n[\nask nation 0 [\n set env home_environment\n]\nask env [\n set wel wealth\n]\n]\nplot wel"
"Environment 1" 1.0 0 -7500403 true "" "let wel  0\nlet env []\nif nation 1 != nobody \n[\nask nation 1 [\n set env home_environment\n]\nask env [\n set wel wealth\n]\n]\nplot wel"
"Environment 2" 1.0 0 -2674135 true "" "let wel  0\nlet env []\nif nation 2 != nobody \n[\nask nation 2 [\n set env home_environment\n]\nask env [\n set wel wealth\n]\n]\nplot wel"
"Environment 3" 1.0 0 -955883 true "" "let wel  0\nlet env []\nif nation 3 != nobody \n[\nask nation 3 [\n set env home_environment\n]\nask env [\n set wel wealth\n]\n]\nplot wel"
"Environment 4" 1.0 0 -6459832 true "" "let wel  0\nlet env []\nif nation 4 != nobody \n[\nask nation 4 [\n set env home_environment\n]\nask env [\n set wel wealth\n]\n]\nplot wel"

INPUTBOX
14
493
169
553
Runtime
1000.0
1
0
Number

TEXTBOX
173
494
304
522
This is the number of years the simulation will run
11
0.0
1

PLOT
948
180
1832
330
Wealth of Nations
Year
Wealth
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Nation 0" 1.0 0 -16777216 true "" "let wel 0\nif nation 0 != nobody \n[\nask nation 0 [\n set wel item year wealth_over_time \n]\n]\nplot wel"
"Nation 1" 1.0 0 -7500403 true "" "let wel 0\nif nation 1 != nobody \n[\nask nation 1 [\n set wel item year wealth_over_time \n]\n]\nplot wel"
"Nation 2" 1.0 0 -2674135 true "" "let wel 0\nif nation 2 != nobody \n[\nask nation 2 [\n set wel item year wealth_over_time \n]\n]\nplot wel"
"Nation 3" 1.0 0 -955883 true "" "let wel 0\nif nation 3 != nobody \n[\nask nation 3 [\n set wel item year wealth_over_time \n]\n]\nplot wel"
"Nation 4" 1.0 0 -6459832 true "" "let wel 0\nif nation 4 != nobody \n[\nask nation 4 [\n set wel item year wealth_over_time \n]\n]\nplot wel"

SWITCH
16
401
119
434
trading
trading
0
1
-1000

SWITCH
17
443
195
476
environment_changes
environment_changes
0
1
-1000

SLIDER
16
309
241
342
Base_value_of_fertility
Base_value_of_fertility
1
20
1.0
1
1
wealth
HORIZONTAL

SLIDER
16
352
188
385
opinion_weight
opinion_weight
0
100
1.0
1
1
NIL
HORIZONTAL

BUTTON
246
31
309
64
NIL
finish
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
11
568
166
628
years_for_statistics
5.0
1
0
Number

TEXTBOX
173
568
323
610
How many years back the simulation will check when looking for significant trends
11
0.0
1

INPUTBOX
12
634
167
694
neighbour_distance
10.0
1
0
Number

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
