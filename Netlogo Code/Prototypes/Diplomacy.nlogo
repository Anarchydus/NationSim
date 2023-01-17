globals [
  year
]

breed[ Nations Nation ]
directed-link-breed[ Relations Relation]
undirected-link-breed[ Trades Trade]
breed[ Wars War]
breed[ Diplomacies Diplomacy]

nations-own [
  ;;How many people are living in a nation
  population

  ;;Nations this nation has a relationship too
  neighbours

  ;;The relationships this nation has
  relationships

  ;;The funding of this nations military
  military_funding

  ;;The size of this nations military
  military_size

  ;;This nations wealth
  wealth

  ;;This nations resources
  resources
]

relations-own [
  ;;The nation that created the relation
  relation_parent

  ;;The opinion of this nation towards the other
  oppinion

  ;;The power this nation has compared to the other's
  relative_power

  ;;A list of all ongoing and ended trades this nation has to it's neighbour
  trade_agreements

  ;;A list of all ongoing and ended wars this nation has to it's neighbour
  warfare

  ;;A list of all ongoing and ended diplomatic treaties this nation has to it's neighbour
  diplomatic_treaties

]


;;SUG This is awful, I need to somehow make these one thing or something, I cannot read this at all

trades-own [
  ;;The two nations involved in the trade
  t_left_end
  t_right_end

  ;;How much wealth is moved
  wealth_trade

  ;;How many resources are moved
  resource_trade

  ;;Duration (-1 for infinite)
  duration

  ;;When the trade was made
  creation_date
]

wars-own [
  ;;The two nations involved in the war
  attacker
  defender

  ;;Victory points scored by either side
  victories

  ;;Whether the war is still ongoing
  ongoing

  ;;When the war started
  start_date

  ;;What the war is about
  conquest

]


diplomacies-own [
  ;;The two nations involved in diplomacy
  d_left_end
  d_right_end

  ;;The active treaties between the nations
  treaties

  ;;The current proposals awaiting confirmation
  proposals

  ;;When the treaty was signed
  signing_date
]



;;**********************************FUNCTIONS****************************************

;;***SETUP AND GO***

;;Function runs once at start of simulation and sets up our nations and relationships
to setup
  clear-all
  set year 0

  create-nations number_of_nations [
    nations.setup
  ]
  ask relations [
    relations.setup
  ]
  reset-ticks
end

;;Runs once per timestep, and updates all our classes
;;SUG some of these definitely do not need to be on surface level like this. Subclasses please, as much as that is possible in netlogo
to go
  if(year < runtime)
  [
    set year year + 1
    ask nations[
      nations.update
    ]
    ask relations [
      relations.update
    ]
    ask trades [
      trades.update
    ]
    ask wars [
      wars.update
    ]
    ask diplomacies [
      diplomacy.update
    ]
    tick
  ]
end

;;******TURTLE SPECIFIC FUNCTIONS******

;;***NATION FUNCTIONS***

;;Runs once at start of simulation and sets up parameters and relationships to other nations
;;SUG aren't these supposed to be two way relationships? Why is it done like this?
to nations.setup

  ;;How many people are living in a nation
  set population (list (random(floor (starting_population / 2))+ floor (starting_population / 2)))

  ;;This nations resources
  set resources (list (random(floor(starting_resources / 2)) + floor (starting_resources / 2)))

  ;;The funding of this nations military
  set military_funding (list (5 + random 15))

  ;;The size of this nations military
  set military_size (list min (list (last resources * (last military_funding / 100)) (last population / 20)))

  ;;This nations wealth
  set wealth (list (random (floor (starting_wealth / 2)) + floor (starting_population / 2 )))

  ;;Nations this nation has a relationship too
  set neighbours other nations

  ;;The relationships this nation has
  create-relations-to neighbours [
    set relation_parent myself
  ]

  set relationships my-out-relations
end

;;Runs once per timestep and updates the parameters of the nation
;;SUG figure out a way to make ressources and wealth less cantankerous
to nations.update

  ;;Update the population list to have this years entry
  set population lput ((last population) + nations.update_population) population

  ;;Find the produced wealth this year
  let production nations.update_production

  ;;Update the current wealth to be last years wealth plus this years production
  set wealth lput (last wealth + item 0 production) wealth

  ;;Update the currently available ressources to be last years resources plus this years production
  set resources lput (last resources + item 1 production) resources

  ;;Update the military of the nation
  nations.update_military

  ;;Remove military ressource drain from this years ressources
  set resources replace-item (length resources - 1) resources (last resources - ((last military_funding / 100) * last resources))

  ;;Update diplomatic relations
  nations.update_diplomacy

end

;;Calculates this years production for the nation
;;WIP the randomness here is ridiculous, these need to be researched formulas
to-report nations.update_production
  ;;Figure out how many people in the population are not in the military (min 0)
  let working_pop min (list (last population - last military_size) 0)

  ;;Every worker produces between 1/4 and 1/2 wealth
  let work_impact (random-float(0.25) + 0.25) * working_pop

  ;;Every tick, we create 0.5 - 0.1 resource for each wealth we create, randomly
  report (list work_impact (work_impact / (random(9) + 1)))
end


;;The same population update function from economy.nlogo, but less advanced due to lack of certain parameters
;;Produces the final population growth for the year
to-report nations.update_population


  ;;(x0,y0) = (max-gdp,min-cbr)
  ;;(x1,y1) = (min-gdp,max-cbr)
  ;;(xp,yp) = (current-gdp, current-cbr)
  ;;Find current rate of births based on how much money we are making
  let min_birthrate 5
  let max_birthrate 50
  let yp  (min_birthrate + ((max_birthrate - min_birthrate) / (0.1 - (first wealth * 1000))) * (last wealth - (first wealth * 1000)) )
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
  set yp 13 + ((1 - 13) / ((first wealth * 1000) - 0.1)) * (last wealth - 0.1)
  let gpd_death_impact min (list (max (list yp 1)) 13)
  set deathrate_factors lput gpd_death_impact deathrate_factors

  let deathrate (mean deathrate_factors) / 1000 ;;deathrate is usually calculated by 1000, we have to divide by 1000 to get per person

  report ((birthrate - deathrate) * last population)
end

;;Updates the military actions of a nation
;;WIP This needs a full overhaul. Research
to nations.update_military

  ;;Find the size of the military from how much funding we are pouring into it
  ;;Cannot be more than the population
  set military_size lput (min (list (last military_funding * last resources) last population)) military_size

  let warlikeness 0

  ;;The lower oppinions we have of our neighbours, the more ongoing wars we have (ongoing or not) we increase our warlikeness
  ask relationships [
    if(last oppinion < 25)
    [
      set warlikeness warlikeness + 1
    ]
    ask wars
    [
      ifelse (ongoing)
      [
      set warlikeness warlikeness + 10
      ]
      [
        set warlikeness warlikeness + 1
      ]
    ]
  ]

  ;;The higher our warlikeness, the more military funding
  set military_funding lput warlikeness military_funding

end

;;Updates all diplomatic interactions between nations
to nations.update_diplomacy

  nations.update_trades

end


;;Updates the current ongoing wars we have
;;WIP This function cannot work as it runs for every relationships with ongoing wars, rather than this nations.
;;Needs a full rewrite
to nations.update_wars
  let owner self

  ;;Find every relationship with ongoing wars
  ask relationships with [count (wars with [ongoing]) > 0]
  [
    ;;Find out who is the aggressor and who is the defender
    let war_status 0
    foreach [self] of wars with [ongoing]
    [ x ->
      let side 0
      ask x
      [
        if(owner = defender)
        [
          set side 1
        ]
      ]
      ;;Once we know if we are attacking or defending, find the status of the war for us
      set war_status relations.find_war_status x side
    ]

    ifelse(war_status >= 50 and war_status < 75)
    [
      ;;begin carefully contemplating ending the war, depending on how important the objectives are

    ]
    [
      ifelse(war_status >= 75 and war_status < 100)
      [
        ;;Roll a dice to see if we end the war
      ]
      [
        ;;Immediately end the war white peace asap
      ]
    ]

  ]
end

;;Function to find out for each war if it is worth it to continue the war, or to just try and white peace out of the war
;;WIP this function does not make any sense
to-report relations.find_war_status [ war_to_check which_end]

  ;;The higher the opinion is, the more we are likely to end the war
  let opinion_impact (oppinion - 50) * 2

  let victories_impact 0
  let attrition_impact 0
  ask war_to_check
  [
    ;;The higher the difference in Victories is, the more they sway ending the war
    set victories_impact ((item which_end victories - item ((which_end - 1) * -1) victories) * 10)

    ;;The longer the war goes on, the more war-attrition we suffer, the more we want to end the war
    set attrition_impact (year - start_date)
  ]

  let war_opinion (list opinion_impact victories_impact attrition_impact)

  report mean war_opinion

end

;;Function which updates which nations we are making trades with
;;WIP overly convoluted mess. Rewrite
to nations.update_trades
  let trade_status nations.find_trade_status

  ifelse( item 0 trade_status = "Low Resources")
  [


    let looking_for_resources true
    let looking_for_best_trades false

    ;;The worst trades for each relationship [relationship, trade, combined_value]
    let worst_trades find_trade looking_for_best_trades looking_for_resources self

    ;;If we have trades that sell resources
    ifelse(length worst_trades > 0)
    [
      ;;Step 2 Find the worst trade in this entire list
      ;;Step 2.1 Sort the entire list by their combined value
      ;;Step 2.2 Take the lowest item in the list, that is the worst trade

      set worst_trades sort-by [[a b]-> item 2 a > item 2 b] worst_trades
      let worst_trade (list (item 0 first worst_trades) (item 1 first worst_trades))

      ;;Step 3 Create a proposal to cancel that trade
      ask item 0 worst_trade
      [
        ask diplomatic_treaties
        [
          set proposals lput (list "cancel trade" (list item 1 worst_trade)) proposals
        ]
      ]
    ]
    [
      ;;ALTERNATIVELY, IF WE HAVE NO BAD TRADES


      set looking_for_resources true
      set looking_for_best_trades true

      let best_trades find_trade looking_for_best_trades looking_for_resources self

      ;;We have trades that buy resources
      ifelse (length best_trades > 0)
        [
          ;;Step 3 Find the single best trade we have across all relations
          ;;Step 3.1 Sort the entire list by their combined value
          ;;Step 3.2 Take the highest item in the list, that is the best trade

          set best_trades sort-by [[a b]-> item 2 a > item 2 b] best_trades
          let best_trade last best_trades

          ;;Step 4 Create a proposal to update that trade
          ask item 0 best_trade
          [
            let old_values trades.values self
            let new_purchase (item 1 old_values * 1.1)
            let new_values (list (new_purchase * item 2 best_trade)  new_purchase)
            ask diplomatic_treaties
            [
              set proposals lput (list "Update trade" new_values) proposals
            ]
          ]
        ]
        ;;Finally, if we do not have any trades that affect resources, we must create a trade to get more
        [
          ;;Step 3.1 Figure out how many resources we need
          ;;Step 3.2 Figure out how much we are willing to pay
          ;;Step 3.3 Find the neighbour we have the highest oppinion of
          ;;Step 3.4 Make a proposal

          ;;Step 3.1
          let demand floor (last resources * item 1 trade_status)

          ;;Step 3.2
          let supply (item 1 trade_status * last wealth)

          ;;Step 3.3
          ask relationships with-max [oppinion]
          [
            ;;Step 3.4
            ask diplomatic_treaties
            [
              set proposals lput(list "Create trade" (list (supply * -1) demand)) proposals
              ]
            ]
          ]
        ]
      ]
      [ ;;If status is not low resources
        ifelse(item 0 trade_status = "High Resources")
        [
          ;;If we have more resources than we need, we can sell them for a profit
          ;;For this, we first find trades that sell wealth, and cancel the least profitable
          let looking_for_resources false
          let looking_for_best_trades false

          let worst_trades find_trade looking_for_best_trades looking_for_resources self

          ifelse(length worst_trades > 0)
          [
            ;;Step 2 Find the worst trade in this entire list
            ;;Step 2.1 Sort the entire list by their combined value
            ;;Step 2.2 Take the lowest item in the list, that is the worst trade

            set worst_trades sort-by [[a b]-> item 2 a > item 2 b] worst_trades
            let worst_trade (list (item 0 first worst_trades) (item 1 first worst_trades))

            ;;Step 3 Create a proposal to cancel that trade
            ask item 0 worst_trade
            [
              ask diplomatic_treaties
              [
                set proposals lput (list "cancel trade" (list item 1 worst_trade)) proposals
              ]
            ]
          ]
          [
            ;;we did not find any trades where we are buying resources
            ;;Now we find the trade where we are selling resources and the price is the best, and then run with that

            set looking_for_resources false
            set looking_for_best_trades true
            let best_trades find_trade looking_for_best_trades looking_for_resources self

            ifelse (length best_trades > 0)
              [
                ;;Step 3 Find the single best trade we have across all relations
                ;;Step 3.1 Sort the entire list by their combined value
                ;;Step 3.2 Take the highest item in the list, that is the best trade

                set best_trades sort-by [[a b]-> item 2 a > item 2 b] best_trades
                let best_trade last best_trades

                ;;Step 4 Create a proposal to update that trade
                ask item 0 best_trade
                [
                  let old_values trades.values self
                  let new_purchase (item 0 old_values * 1.1)
                  let new_values (list new_purchase (new_purchase * item 2 best_trade))
                  ask diplomatic_treaties
                  [
                    set proposals lput (list "Update trade" new_values) proposals
                  ]
                ]
              ]
              [
                ;;We did not end up finding any trades selling or buying resources
                ;;Step 3.1
                let demand floor (last wealth * item 1 trade_status)

                ;;Step 3.2
                let supply (item 1 trade_status * last resources)

                ;;Step 3.3
                ask relationships with-max [oppinion]
                [
                  ;;Step 3.4
                  ask diplomatic_treaties
                  [
                    set proposals lput (list "Create trade" (list demand (supply * -1))) proposals
                    ]
                  ]
                ]
              ]
            ]
            [

            ]
          ]
end

;;Finds what we currently need, trade wise
to-report nations.find_trade_status

  ;;How much the military has grown on average over the last 10 years
  let military_chart 0
  let resource_chart 0
  ;;If we have enough years to check the last ten years
  ifelse( year > 10)
  [
    ;;Use the last ten years for statistics
    set military_chart (sublist military_funding (length military_funding - 11) (length military_funding))
    set resource_chart (sublist resources (length resources - 11) (length resources))
  ]
  [
    ;;Else we just check the last year
    set military_chart (sublist military_funding (0) (length military_funding))
    set resource_chart (sublist resources (0) (length resources))
  ]

  ;;Find how much our military growth and resource gain have grown
  let military_percent_growth 0
  let resource_percent_growth 0

  ;;If there are both military and resources, we find out how many percents they have grown with
  if(last military_chart > 0 and last resource_chart > 0)
  [
    ;;Find how much we are projected to grow this year via the average of our charts growth over the specified time
    ;;Then divide that by our latest value to see how much growth that represents
    let military_projected_growth (last military_chart - first military_chart) / length military_chart
    set military_percent_growth  military_projected_growth / last military_chart

    let resource_projected_growth (last resource_chart - first resource_chart) / length resource_chart
    set resource_percent_growth resource_projected_growth / last resource_chart
  ]

  ;;If we have more military growth than the resource growth to support that, we have to few resources.
  ;;Else we have more resources than we need
  ifelse(military_percent_growth > resource_percent_growth)
  [
    report (list "Low Resources" (military_percent_growth - resource_percent_growth))
  ]
  [
    report (list "High Resources" (resource_percent_growth - military_percent_growth))
  ]
end

;;***RELATION FUNCTIONS***

;;Runs once at the start of the simulation and sets up all parameters of a relationship
to relations.setup
  ;;Sets starting oppinion between 0 and 100
  set oppinion  (list clamp (25 + random starting_oppinion) 0 100)

  let parent_power 0
  let target_power 0

  ;;Find the power of the nation based on their military strength
  ;;WIP this needs to factor in moe than military strength
  ask relation_parent [
    set parent_power ((first military_funding * first resources) + first military_size )
    ask other-end [
      set target_power ((first military_funding * first resources) + first military_size )
    ]
  ]

  ;;Find the relative strength of this nation compared to the opposing nation
  set relative_power parent_power - target_power

  ;;Make empty lists for other classes that are tracked by this one.
  ;;SUG again this should be done differently
  set trade_agreements []
  set warfare []

  set diplomatic_treaties []
end

;;Runs once per timestep to update all parameters of relations
to relations.update

  let parent_power 0
  let target_power 0

  ;;Find the relative power again for this timestep
  ask relation_parent [

    set parent_power (last military_size + (last military_funding * last resources))
    ask other-end [
      set target_power (last military_size + (last military_funding * last resources))
    ]
  ]

  set relative_power parent_power - target_power

  ;;Update the opinions of the nations in question
  relations.update_oppinion

end

;;Updates the opinions the two nations have of eachother
to relations.update_oppinion
  let parent_power 0
  ;;Find the power of the owning nation
  ask relation_parent
  [
    set parent_power (last military_size * (last military_funding * last resources))
  ]

  ;;WIP NO idea what is going on in this line
  let power_imbalance_modifier clamp  (abs (( (parent_power / (max (list relative_power 1)) ) - 1) * 100)) 0 100 ;;The smaller the difference, the less the impact

  ;;let historical_modifier clamp (length diplomatic_treaties - length warfare) 0 100 ;;The more wars and the less diplomatic_treaties the worse oppinion

  ;;We update our opinion
  ;;WIP again, this makes no sense to me
  set oppinion lput (clamp (last oppinion - power_imbalance_modifier) 0 100) oppinion
end

;;Go through our trades and find the trade that matches the criteria, namely if we are buying or selling resources, and if we are looking for the trade that is best performing, or worst performing
to-report find_trade [ best resource owner_nation]


  let trade_goods 0
  if(resource = true)
  [
    set trade_goods  1
  ]

  ifelse(best = true)
  [
    let best_trades []
    ask relations with [(count ((link-set trade_agreements) with [duration > 0])) > 0]
      [
        let highest_gain 0
        let best_performing_trade nobody

        ask (link-set trade_agreements) with [duration > 0]
        [
          let values trades.values owner_nation

          if(item trade_goods values > 0)
          [
            let combined_value (item ((trade_goods - 1) * -1) values * -1) / item trade_goods values

            if (combined_value > highest_gain)
            [
              set highest_gain combined_value
              set best_performing_trade self
            ]
          ]
        ]

        if(best_performing_trade != nobody)
        [
          set best_trades lput (list self best_performing_trade highest_gain) best_trades
        ]
    ]
    report best_trades
  ]
  [
    let worst_trades []
    ask relationships with [(count ((link-set trade_agreements) with [duration > 0])) > 0]
    [
      let lowest_gain 999999999
      let worst_performing_trade nobody

      ask (link-set trade_agreements) with [duration > 0]
      [
        let values trades.values owner_nation
        ;;Step 1.2.1
        if(item trade_goods values < 0)
        [
          ;;Step 1.2
          let combined_value item ((trade_goods - 1) * -1) values / (item trade_goods values * -1)

          ;;Step 1.3
          if (combined_value < lowest_gain)
          [
            set lowest_gain combined_value
            set worst_performing_trade self
          ]
        ]
      ]

      ;;Step 1.4
      if(worst_performing_trade != nobody)
      [
        set worst_trades lput (list self worst_performing_trade lowest_gain) worst_trades
      ]
    ]
    report worst_trades
  ]
end

;;*** TRADE FUNCTIONS ***

;;updates our trade function once per timestep
to trades.update

  ;;For every timestep, update the left and right end with how much money is being made, how many resources are being lost / vice versa
  let trade_values (list wealth_trade  resource_trade)
  ask t_left_end
  [
    set wealth replace-item (length wealth - 1) wealth (last wealth + item 0 trade_values)
    set resources replace-item (length resources - 1) resources (last resources + item 1 trade_values)
  ]

  ask t_right_end [
    set wealth replace-item (length wealth - 1) wealth (last wealth - item 0 trade_values)
    set resources replace-item (length resources - 1) resources (last resources - item 1 trade_values)
  ]

  ;;count down the remaining duration of the trade, unless it is no longer running, or it is meant to run indefinitely
  if(duration > 0)
  [
    set duration duration - 1
  ]
end

;;Finds out if we are selling or buying in this trade
to-report trades.values [which_end]
  if(t_left_end = which_end)
  [
    report (list wealth_trade resource_trade)
  ]
  ifelse(t_right_end = which_end)
  [
    report (list (wealth_trade * -1) (resource_trade * -1))
  ]
  [
    show (word "Error, no end equal to " which_end " exists.")
  ]
end

;;*** WAR FUNCTIONS ***


;;Just a bunch of non-finished functions for updating
to wars.update
end

;;*** DIPLOMACY FUNCTIONS ***

to diplomacy.update
end

;;*** HELPER FUNCTIONS ***

;;Function that releases me from having to write this out every time I want to clamp something
to-report clamp [value minimum maximum]
  report min (list (max (list value minimum)) maximum)
end
@#$#@#$#@
GRAPHICS-WINDOW
222
10
659
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

SLIDER
0
85
172
118
runtime
runtime
10
1000
100.0
10
1
years
HORIZONTAL

SLIDER
0
124
202
157
number_of_nations
number_of_nations
1
100
9.0
1
1
Nations
HORIZONTAL

BUTTON
1
10
64
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
68
10
150
43
One step
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
153
10
216
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
161
178
194
starting_population
starting_population
1000
100000
15000.0
1000
1
NIL
HORIZONTAL

SLIDER
0
199
172
232
starting_wealth
starting_wealth
1000
100000
12000.0
1000
1
NIL
HORIZONTAL

SLIDER
0
237
174
270
starting_resources
starting_resources
1000
100000
10000.0
1000
1
NIL
HORIZONTAL

PLOT
666
11
1404
161
Nation wealth
NIL
NIL
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Nation 0" 1.0 0 -16777216 true "" "let profit 0\nif nation 0 != nobody[\n ask nation 0 [\n  set profit last wealth\n ]\n]\nplot profit"
"Nation 1" 1.0 0 -7500403 true "" "let profit 0\nif nation 1 != nobody[\n ask nation 1 [\n  set profit last wealth\n ]\n]\nplot profit"
"Nation 2" 1.0 0 -2674135 true "" "let profit 0\nif nation 2 != nobody[\n ask nation 2 [\n  set profit last wealth\n ]\n]\nplot profit"
"Nation 3" 1.0 0 -955883 true "" "let profit 0\nif nation 3 != nobody[\n ask nation 3 [\n  set profit last wealth\n ]\n]\nplot profit"
"Nation 4" 1.0 0 -6459832 true "" "let profit 0\nif nation 4 != nobody[\n ask nation 4 [\n  set profit last wealth\n ]\n]\nplot profit"

PLOT
668
166
1405
316
Nation Population
NIL
NIL
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Nation 0" 1.0 0 -16777216 true "" "let pop 0\nif nation 0 != nobody[\n ask nation 0 [\n  set pop last population\n ]\n]\nplot pop"
"Nation 1" 1.0 0 -7500403 true "" "let pop 0\nif nation 1 != nobody[\n ask nation 1 [\n  set pop last population\n ]\n]\nplot pop"
"Nation 2" 1.0 0 -2674135 true "" "let pop 0\nif nation 2 != nobody[\n ask nation 2 [\n  set pop last population\n ]\n]\nplot pop"
"Nation 3" 1.0 0 -955883 true "" "let pop 0\nif nation 3 != nobody[\n ask nation 3 [\n  set pop last population\n ]\n]\nplot pop"
"Nation 4" 1.0 0 -6459832 true "" "let pop 0\nif nation 4 != nobody[\n ask nation 4 [\n  set pop last population\n ]\n]\nplot pop"

PLOT
668
320
1406
470
Nation Resources
NIL
NIL
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Nation 0" 1.0 0 -16777216 true "" "let res 0\nif nation 0 != nobody[\n ask nation 0 [\n  set res last resources\n ]\n]\nplot res"
"Nation 1" 1.0 0 -7500403 true "" "let res 0\nif nation 2 != nobody[\n ask nation 2 [\n  set res last resources\n ]\n]\nplot res"
"Nation 2" 1.0 0 -2674135 true "" "let res 0\nif nation 2 != nobody[\n ask nation 2 [\n  set res last resources\n ]\n]\nplot res"
"Nation 3" 1.0 0 -955883 true "" "let res 0\nif nation 3 != nobody[\n ask nation 3 [\n  set res last resources\n ]\n]\nplot res"
"Nation 4" 1.0 0 -6459832 true "" "let res 0\nif nation 4 != nobody[\n ask nation 4 [\n  set res last resources\n ]\n]\nplot res"

SLIDER
0
274
172
307
starting_oppinion
starting_oppinion
0
100
50.0
1
1
NIL
HORIZONTAL

PLOT
668
473
1407
623
Military Funding
NIL
NIL
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Nation 0" 1.0 0 -7500403 true "" "let funding 0\nask nation 0 [\nset funding last military_funding\n]\nplot funding"
"Nation 1" 1.0 0 -2674135 true "" "let funding 0\nask nation 1 [\nset funding last military_funding\n]\nplot funding"
"Nation 2" 1.0 0 -955883 true "" "let funding 0\nask nation 2 [\nset funding last military_funding\n]\nplot funding"
"Nation 3" 1.0 0 -6459832 true "" "let funding 0\nask nation 3 [\nset funding last military_funding\n]\nplot funding"
"Nation 4" 1.0 0 -1184463 true "" "let funding 0\nask nation 4 [\nset funding last military_funding\n]\nplot funding"

PLOT
65
474
664
624
Military
NIL
NIL
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Nation 0" 1.0 0 -16777216 true "" "let military 0\nask nation 0 [\nset military last military_size\n]\nplot military"
"Nation 1" 1.0 0 -7500403 true "" "let military 0\nask nation 1 [\nset military last military_size\n]\nplot military"
"Nation 2" 1.0 0 -2674135 true "" "let military 0\nask nation 2 [\nset military last military_size\n]\nplot military"
"Nation 3" 1.0 0 -955883 true "" "let military 0\nask nation 3 [\nset military last military_size\n]\nplot military"
"Nation 4" 1.0 0 -6459832 true "" "let military 0\nask nation 4 [\nset military last military_size\n]\nplot military"

PLOT
1409
12
2140
162
Diplomatic Proposals
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

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
