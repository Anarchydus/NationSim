breed [nations nation]
breed [markets market]

nations-own [
  ;;Nations identifier
  name

  ;;The nations wealth
  wealth_over_time

  ;;The nations resources (P)
  resources_over_time

  ;;The nations population (L)
  population_over_time

  ;;The nations technology level for each resource (Pnl)
  technology_levels

  ;;How much the nation wants any specific good
  desires

  ;;Value of each resource
  resource_values

  ;;other nations in the program
  neighbours



]

markets-own [

  ;;How much the market owns of each resource
  international_resource_storage

  ;;How much each good costs
  international_prices

  ;;How much each good is worth initially
  initial_prices
]

globals [
  year ;;current year
  name_list
  resource_list
]

to setup

  clear-all
  set year 0
  set name_list ( list 1 "Germany" "France" "Norway" "Britain" "Sweden" "Finland" "Denmark" "Italy" "Spain" "Portugal" )
  set  resource_list  (list "Wood" "Stone" "Iron" "Copper" "Silver" "Gold" "Uranium" "Lifestock" "Cotton" "Produce")
   create-nations number_of_nations[
    nations.setup
  ]
  create-markets 1 [
    markets.setup
  ]

  reset-ticks
end

to test
  let i 0
  let number_of_failures 0
  let to_many_export 0
  let no_export 0
  let no_labor 0
  let successes 0
  let absolutely_fucked 0
  let recalculating 0

  ;;Test 3 variables
  let S1 0 ;;Is H2 larger than H1 in a success
  let S2 0 ;;Is L2 larger than L1 in a success
  let S3 0 ;;Is L1 larger than H1 in a success
  let S4 0 ;;Is Rl larger than Rh in a success

  ;;Inclusives
  let S12 0 ;; Both S1 and S2 are true
  let S13 0 ;; Both S1 and S3 are true
  let S14 0 ;; Both S1 and S4 are true
  let S23 0 ;; Both S2 and S3 are true
  let S24 0 ;; Both S2 and S4 are true
  let S34 0 ;; Both S3 and S4 are true
  let S123 0
  let S124 0
  let S134 0
  let S234 0

  ;;Exclusives
  let S1!2 0
  let S1!3 0
  let S1!4 0
  let S2!1 0
  let S2!3 0
  let S2!4 0
  let S3!1 0
  let S3!2 0
  let S3!4 0
  let S4!1 0
  let S4!2 0
  let S4!3 0

  let F1 0 ;;Is H2 larger than H1 in a failure
  let F2 0 ;;Is L2 larger than L1 in a failure
  let F3 0 ;;Is L1 larger than H1 in a failure
  let F4 0 ;;Is Rl larger than Rh in a failure

  ;;Inclusives
  let F12 0 ;; Both F1 and F2 are true
  let F13 0 ;; Both S1 and F3 are true
  let F14 0 ;; Both F1 and F4 are true
  let F23 0 ;; Both F2 and F3 are true
  let F24 0 ;; Both F2 and F4 are true
  let F34 0 ;; Both F3 and F4 are true
  let F123 0
  let F124 0
  let F134 0
  let F234 0

  ;;Exclusives
  let F1!2 0
  let F1!3 0
  let F1!4 0
  let F2!1 0
  let F2!3 0
  let F2!4 0
  let F3!1 0
  let F3!2 0
  let F3!4 0
  let F4!1 0
  let F4!2 0
  let F4!3 0

  while [ i < number_of_tests]
 [
    let product_value n-values number_of_products [list (precision (0.01 + random-float 4.99) 2)  (precision (0.01 + random-float 4.99) 2)]
    let i_desires n-values number_of_products [(precision (0.01 + random-float 0.99) 2)]
    let labor (initial_population_min + random (initial_population_max - initial_population_min))

    ifelse(test_chooser = "Test 1")
    [
      let result test1 labor product_value i_desires
      ifelse( item 0 result != 2)
      [
        ifelse( item 0 result = 0)
        [
          set no_export no_export + 1
        ]
        [
          ifelse ( item 0 result = 1)
          [
            set no_labor no_labor + 1
          ]
          [
            ifelse (item 0 result = 3)
            [
              set number_of_failures number_of_failures + 1
              set to_many_export to_many_export + 1
            ]
            [
              ifelse (item 0 result = 4)
              [
              set number_of_failures number_of_failures + 1
              ]
              [
                if( number_of_tests < 1000)
                [
                  show "Test failed to return positive and make sense. Inputs where: Product Values: "
                  show product_value
                  show (word "Labor: " labor)
                  show "Desires: "
                  show i_desires
                  show (word "Final result: " item 1 result)
                ]
                if (item 2 result)
                [
                  set recalculating recalculating + 1
                ]
                set absolutely_fucked absolutely_fucked + 1
              ]
            ]
          ]
        ]
      ]
      [
        set successes successes + 1
      ]
    ]
    [
      ifelse(test_chooser = "Test 2")
      [
        let result test2 (item 0 i_desires) (item 0 i_desires / sum(i_desires)) (item 1 i_desires) (Item 1 i_desires / sum(i_desires))
        (item 0 item 0 product_value) (item 1 item 0 product_value) (item 0 item 1 product_value) (item 1 item 1 product_value)
        ifelse (result = 0)
        [
          set no_labor no_labor + 1
        ]
        [
          ifelse (result = 1)
          [
            set number_of_failures number_of_failures + 1
          ]
          [
            set successes successes + 1
          ]
        ]
      ]
      [
        ifelse(test_chooser = "Test 3")
          [
            let result test3 (item 0 i_desires) (item 0 i_desires / sum(i_desires)) (item 1 i_desires) (Item 1 i_desires / sum(i_desires))
            (item 0 item 0 product_value) (item 1 item 0 product_value) (item 0 item 1 product_value) (item 1 item 1 product_value)

            ifelse(result = 0)
            [
              set no_labor no_labor + 1
            ]
            [
              ifelse(result = 1)
              [
                set no_export no_export + 1
              ]
              [
                ifelse( first result = true)
                [
                  if (item 1 result = true)
                  [
                    set S1 S1 + 1
                    ifelse( item 2 result = true)
                    [
                      set S12 S12 + 1
                      if (item 3 result = true)
                      [
                        set S123 S123 + 1
                      ]
                      if (item 4 result = true)
                      [
                        set S124 S124 + 1
                      ]
                    ]
                    [
                      set S1!2 S1!2 + 1
                    ]
                    ifelse(item 3 result = true)
                    [
                      set S13 S13 + 1
                      if (item 4 result = true)
                      [
                        set S134 S134 + 1
                      ]
                    ]
                    [
                      set S1!3 S1!3 + 1
                    ]
                    ifelse(item 4 result = true)
                    [
                      set S14 S14 + 1
                    ]
                    [
                      set S1!4 S1!4 + 1
                    ]
                  ]
                  if (item 2 result = true)
                  [
                    set S2 S2 + 1
                    ifelse( item 1 result = true)
                    [
                      set S12 S12 + 1
                    ]
                    [
                      set S2!1 S2!1 + 1
                    ]
                    ifelse(item 3 result = true)
                    [
                      set S23 S23 + 1
                      if( item 4 result = true)
                      [
                        set S234 S234 + 1
                      ]
                    ]
                    [
                      set S2!3 S2!3 + 1
                    ]
                    ifelse(item 4 result = true)
                    [
                      set S24 S24 + 1
                    ]
                    [
                      set S2!4 S2!4 + 1
                    ]
                  ]
                  if (item 3 result = true)
                  [
                    set S3 S3 + 1
                    ifelse( item 2 result = true)
                    [
                      set S23 S23 + 1
                    ]
                    [
                      set S3!2 S3!2 + 1
                    ]
                    ifelse(item 1 result = true)
                    [
                      set S13 S13 + 1
                    ]
                    [
                      set S3!1 S3!1 + 1
                    ]
                    ifelse(item 4 result = true)
                    [
                      set S34 S34 + 1
                    ]
                    [
                      set S3!4 S3!4 + 1
                    ]
                  ]
                  if (item 4 result = true)
                  [
                    set S4 S4 + 1
                    ifelse( item 2 result = true)
                    [
                      set S24 S24 + 1
                    ]
                    [
                      set S4!2 S4!2 + 1
                    ]
                    ifelse(item 3 result = true)
                    [
                      set S34 S34 + 1
                    ]
                    [
                      set S4!3 S4!3 + 1
                    ]
                    ifelse(item 1 result = true)
                    [
                      set S14 S14 + 1
                    ]
                    [
                      set S4!1 S4!1 + 1
                    ]
                  ]
                  set successes successes + 1
                ]
                [
                  if (item 1 result = true)
                  [
                    set F1 F1 + 1
                    ifelse( item 2 result = true)
                    [
                      set F12 F12 + 1
                      if (item 3 result = true)
                      [
                        set F123 F123 + 1
                      ]
                      if (item 4 result = true)
                      [
                        set F124 F124 + 1
                      ]
                    ]
                    [
                      set F1!2 F1!2 + 1
                    ]
                    ifelse(item 3 result = true)
                    [
                      set F13 F13 + 1
                      if (item 4 result = true)
                      [
                        set F134 F134 + 1
                      ]
                    ]
                    [
                      set F1!3 F1!3 + 1
                    ]
                    ifelse(item 4 result = true)
                    [
                      set F14 F14 + 1
                    ]
                    [
                      set F1!4 F1!4 + 1
                    ]
                  ]
                  if (item 2 result = true)
                  [
                    set F2 F2 + 1
                    ifelse( item 1 result = true)
                    [
                      set F12 F12 + 1
                    ]
                    [
                      set F2!1 F2!1 + 1
                    ]
                    ifelse(item 3 result = true)
                    [
                      set F23 F23 + 1
                      if( item 4 result = true)
                      [
                        set F234 F234 + 1
                      ]
                    ]
                    [
                      set F2!3 F2!3 + 1
                    ]
                    ifelse(item 4 result = true)
                    [
                      set F24 F24 + 1
                    ]
                    [
                      set F2!4 F2!4 + 1
                    ]
                  ]
                  if (item 3 result = true)
                  [
                    set F3 F3 + 1
                    ifelse( item 2 result = true)
                    [
                      set F23 F23 + 1
                    ]
                    [
                      set F3!2 F3!2 + 1
                    ]
                    ifelse(item 1 result = true)
                    [
                      set F13 F13 + 1
                    ]
                    [
                      set F3!1 F3!1 + 1
                    ]
                    ifelse(item 4 result = true)
                    [
                      set F34 F34 + 1
                    ]
                    [
                      set F3!4 F3!4 + 1
                    ]
                  ]
                  if (item 4 result = true)
                  [
                    set F4 F4 + 1
                    ifelse( item 2 result = true)
                    [
                      set F24 F24 + 1
                    ]
                    [
                      set F4!2 F4!2 + 1
                    ]
                    ifelse(item 3 result = true)
                    [
                      set F34 F34 + 1
                    ]
                    [
                      set F4!3 F4!3 + 1
                    ]
                    ifelse(item 1 result = true)
                    [
                      set F14 F14 + 1
                    ]
                    [
                      set F4!1 F4!1 + 1
                    ]
                  ]
                  set number_of_failures number_of_failures + 1
                ]
              ]
            ]
        ]
        [
          ifelse (test_chooser = "Test 4")
          [
            let result test4 labor product_value i_desires
            ifelse( item 0 result != 2)
            [
              ifelse( item 0 result = 0)
              [
                set no_export no_export + 1
              ]
              [
                ifelse ( item 0 result = 1)
                [
                  set no_labor no_labor + 1
                ]
                [
                  if (item 0 result = 3)
                  [
                    set number_of_failures number_of_failures + 1
                  ]
                ]
              ]
            ]
            [
              set successes successes + 1
            ]
          ]
          [
            ifelse(test_chooser = "Test 5")
            [
              let result  test5 product_value i_desires labor

              if(result = 0)
              [
                set no_labor no_labor + 1
              ]
              if(result = 1 )
              [
                set no_export no_export + 1
              ]
              if(result = 2 )
              [
                set successes successes + 1
              ]
              if(result = 3 )
              [
                set number_of_failures number_of_failures + 1
              ]
            ]
            [
               ifelse(test_chooser = "Test 6")
              [
                let result test6 product_value i_desires labor
                if(item 0 result = 0)
                [
                  set no_labor no_labor + 1
                ]
                if(item 0 result = 1 )
                [
                  set no_export no_export + 1
                ]
                if(item 0 result = 2)
                [
                  set successes successes + 1
                ]
                if(item 0 result = 3)
                [
                  set number_of_failures number_of_failures + 1
                ]
              ]
              [
              ]
            ]
          ]
        ]
      ]
    ]
    set i i + 1
  ]

  ifelse (test_chooser = "Test 3")
  [
    show (word "Successful tests: " successes)
    show(word "The following occurances happened in successful tests.")
    show (word "The good with the highest price on the international market had a higher price internationally than locally: " S1 " vs " (successes -  S1))
    show(word "The good with the lower price on the international market had a higher price internationally than locally: " S2 " vs " (successes - S2))
    show(word "The good with the lower price on the international market had a higher price locally than the good with the highest price on the international market: " S3 " vs " (successes - S3))
    show(word "The available labor for the good with the lower price on the international market was higher than that for the good with the higher price: " S4 " vs "(successes - S4))
    show "Inclusives---------------------------------------------------------------------------------------------------------"
    show (word "The International price for both the export and import good was higher than the national price: " S12 " vs " (successes - S12))
    show (word "Export-international > Export-national & import-national > export-national: " S13 " vs " (successes - S13))
    show (word "Export-international > Export-national & Available labor import > Available labor export: " S14 " vs " (successes - S14))
    show (word "Import-international > import-national & import-national > export-national: " S23 " vs " (Successes - S23))
    show (word "Import-international > import-national &  Available labor import > Available labor export: " S24 " vs " (Successes - S24))
    show (word "Import-national > export-national &  Available labor import > Available labor export: " S34 " vs " (Successes - S34))
    show (word "Export-international > Export-national & Import-international > import-national & import-national > export-national: " S123 " vs " (successes - S123))
    show (word "Export-international > Export-national & Import-international > import-national & Available labor import > Available labor export: " S124 " vs " (successes - S124))
    show (word "Export-international > Export-national & import-national > export-national & Available labor import > Available labor export: " S134 "vs " (successes - S134))
    show (word "Import-international > import-national & import-national > export-national & Available labor import > Available labor export: " S234 " vs " (successes - S234))
    show "Exclusives---------------------------------------------------------------------------------------------------------"
    show (word "Export-international > Export-national ! Import-international > import-national: " S1!2 " vs " (successes - S1!2))
    show (word "Export-international > Export-national ! import-national > export-national: " S1!3 " vs " (successes - S1!3))
    show (word "Export-international > Export-national ! Available labor import > Available labor export: " S1!4 " vs " (successes - S1!4))
    show (word " Import-international > import-national ! Export-international > Export-national: " S2!1 " vs " (successes - S2!1))
    show (word " Import-international > import-national ! import-national > export-national: " S2!3 " vs " (successes - S2!3))
    show (word " Import-international > import-national ! Available labor import > Available labor export: " S2!4 " vs " (successes - S2!4))
    show (word "import-national > export-national ! Export-international > Export-national: " S3!1 " vs " (successes - S3!1))
    show (word "import-national > export-national ! Import-international > import-national: " S3!2 " vs " (successes - S3!2))
    show (word "import-national > export-national ! Available labor import > Available labor export: " S3!4 " vs " (successes - S3!4))
    show (word "Available labor import > Available labor export ! Export-international > Export-national: " S4!1 " vs " (successes - S4!1))
    show (word "Available labor import > Available labor export ! Import-international > import-national: " S4!2 " vs " (successes - S4!2))
    show (word "Available labor import > Available labor export ! import-national > export-national: " S4!3 " vs " (successes - S4!3))

    show (word "Failed tests: " number_of_failures)
    show(word "The following occurances happened in successful tests.")
    show (word "The good with the highest price on the international market had a higher price internationally than locally: " F1 " vs " (number_of_failures -  F1))
    show(word "The good with the lower price on the international market had a higher price internationally than locally: " F2 " vs " (number_of_failures - F2))
    show(word "The good with the lower price on the international market had a higher price locally than the good with the highest price on the international market: " F3 " vs " (number_of_failures - F3))
    show(word "The available labor for the good with the lower price on the international market was higher than that for the good with the higher price: " F4 " vs "(number_of_failures - F4))
    show "Inclusives---------------------------------------------------------------------------------------------------------"
    show (word "The International price for both the export and import good was higher than the national price: " F12 " vs " (number_of_failures - S12))
    show (word "Export-international > Export-national & import-national > export-national: " F13 " vs " (number_of_failures - S13))
    show (word "Export-international > Export-national & Available labor import > Available labor export: " F14 " vs " (number_of_failures - S14))
    show (word "Import-international > import-national & import-national > export-national: " F23 " vs " (number_of_failures - S23))
    show (word "Import-international > import-national &  Available labor import > Available labor export: " F24 " vs " (number_of_failures - S24))
    show (word "Import-national > export-national &  Available labor import > Available labor export: " F34 " vs " (number_of_failures - S34))
    show (word "Export-international > Export-national & Import-international > import-national & import-national > export-national: " F123 " vs " (number_of_failures - F123))
    show (word "Export-international > Export-national & Import-international > import-national & Available labor import > Available labor export: " F124 " vs " (number_of_failures - F124))
    show (word "Export-international > Export-national & import-national > export-national & Available labor import > Available labor export: " F134 "vs " (number_of_failures - F134))
    show (word "Import-international > import-national & import-national > export-national & Available labor import > Available labor export: " F234 " vs " (number_of_failures - F234))
    show "Exclusives---------------------------------------------------------------------------------------------------------"
    show (word "Export-international > Export-national ! Import-international > import-national: " F1!2 " vs " (number_of_failures - F1!2))
    show (word "Export-international > Export-national ! import-national > export-national: " F1!3 " vs " (number_of_failures - F1!3))
    show (word "Export-international > Export-national ! Available labor import > Available labor export: " F1!4 " vs " (number_of_failures - F1!4))
    show (word " Import-international > import-national ! Export-international > Export-national: " F2!1 " vs " (number_of_failures - F2!1))
    show (word " Import-international > import-national ! import-national > export-national: " F2!3 " vs " (number_of_failures - F2!3))
    show (word " Import-international > import-national ! Available labor import > Available labor export: " F2!4 " vs " (number_of_failures - F2!4))
    show (word "import-national > export-national ! Export-international > Export-national: " F3!1 " vs " (number_of_failures - F3!1))
    show (word "import-national > export-national ! Import-international > import-national: " F3!2 " vs " (number_of_failures - F3!2))
    show (word "import-national > export-national ! Available labor import > Available labor export: " F3!4 " vs " (number_of_failures - F3!4))
    show (word "Available labor import > Available labor export ! Export-international > Export-national: " F4!1 " vs " (number_of_failures - F4!1))
    show (word "Available labor import > Available labor export ! Import-international > import-national: " F4!2 " vs " (number_of_failures - F4!2))
    show (word "Available labor import > Available labor export ! import-national > export-national: " F4!3 " vs " (number_of_failures - F4!3))
    show (word "We failed due to no remaining labor: " no_labor)
    show (word "We failed due to no export goods: " no_export)
  ]
  [
    show (word "Successful tests: " successes )
    show (word "Number of times we had no export resource: " no_export )
    show (word "Number of times all resources were export resources: " to_many_export)
    show (word "Number of times we had no labor remaining: " no_labor )
    show (word "Failed tests: " number_of_failures)
    show (word "Fucked tests: " absolutely_fucked)
    show (word "Thereof recalculateds: " recalculating)
    Show "Percentages:"
    show (word "Successful: " round(( successes / number_of_tests) * 100 ) " Export failure: " round(( no_export / number_of_tests) * 100 ) " Labor failure: " round(( no_labor / number_of_tests) * 100 ) " Failure: " round(( number_of_failures / number_of_tests) * 100 )
      " Many exports failure: " round(( to_many_export / number_of_tests) * 100 ) " Number of failures where not all resources are exports: " (number_of_failures - to_many_export) " Number of total mission failures: " (absolutely_fucked / number_of_tests))
  ]
end

to go
 if(year < runtime)
  [
    set year (year + 1)
    ;;show (word "Year: " year)

    let international_market one-of markets

  ;;  let outputs []
  ;;  print "Production in Autarky:"
  ;;  ask nations[
  ;;    set outputs nations.calculate_outputs

  ;;    let output_string ""
  ;;    let i 0
  ;;    let profit 0
  ;;    while [i < number_of_products]
  ;;    [
  ;;      set output_string (word output_string  item i resource_list  ": "  item i outputs  ", Value: " (precision (item i outputs * item i resource_values)1) " ")
  ;;      set profit profit + (precision (item i outputs * item i resource_values)1)
  ;;      set i i + 1
  ;;    ]
  ;;    set output_string (word output_string "Total value produced: " profit)
      ;;show output_string
  ;;  ]


    ;;Nation[Product[Comparison[Production Prices]]]
    ;;Value of labor = labor assigned * tech level * national price
    ;;International value of Labor = labor assigned * tech level * international price
    ;;If Value of labor < International value of labor -> Export
    ;;If Value of labor > International value of labor -> Import
    ;;For this, assume labor = 1

    ask markets [
      markets.update
    ]

    let inter_prices last [international_prices] of international_market

    ;;print "Costs of opportunity: "
    let i 0
    while [ i < number_of_products]
    [
      ;;print (word "Resource: " item i resource_list)
      ask nations [
        let suggestion ""
        let national_value  (precision (item i technology_levels * item i resource_values) 1 )
        let international_value (precision (item i technology_levels * item i inter_prices)1)
        ifelse( international_value > national_value)
        [
          set suggestion " Item should be exported"
        ]
        [
          set suggestion " Item should be imported"
        ]
        ;;Print (word self "; National value of labor:" (precision (item i technology_levels * item i resource_values) 1 )", International value of labor: " (precision (item i technology_levels * item i inter_prices)1) suggestion )
      ]
      set i i + 1
    ]

    ask nations[
      let trade_result nations.trade international_market
      ifelse(item 0 trade_result)
      [
        if(debug)
        [
          show (word "Trade was a success!")
          show item 1 trade_result
        ]
      ]
      [
        ;;show item 1 trade_result
        if(debug)
        [
          if(item 2 trade_result = 0)
          [
            show ( "Trade failed due to no available labor")
          ]
          if(item 2 trade_result = 1)
          [
            show ("Trade failed due to no available export resources")
          ]
          if(item 2 trade_result = 3)
          [
            show ("Trade failed to produce profits")
          ]
        ]
      ]
    ]

    tick
  ]
end

;;Nation functions----------------------------------------------------------------------------------------------------------------------------------------------------

to nations.setup

  let name_index item 0 name_list
  set name item name_index name_list

  ;;Update the index for the next nation
  set name_list replace-item 0 name_list ((item 0 name_list) + 1)

  set wealth_over_time (list initial_wealth)
  set population_over_time (list ((random initial_population_max) + initial_population_min))

  ;;Fill list of products
  set resources_over_time n-values number_of_products [(list 0)]

  ;;Find techology for each product, each being between 1 and 5
  set technology_levels n-values number_of_products [precision ((random-float 4) + 1) 2]

  ;;Desires is how much of a product each person in the nation wants at minimum
  set desires n-values number_of_products [precision (0.01 + random-float 0.99) 2]

  set resource_values []
  let i 0
  while [i < number_of_products]
  [
    ;;We set 0 as the minimum value for any item, as no item can have negative value
    set resource_values lput (precision (item i desires * item i technology_levels)2) resource_values
    set i i + 1
  ]

  set neighbours other nations
end


;;Tests the math in a variety of scenarios
to-report test1 [labor labor_values i_desires]

  let export_goods []
  let min_outputs []
  let desire_percentages []
  let required_labor 0

  let i 0
  while [i < number_of_products]
  [

    let resource item i labor_values
    if (item 0 resource < item 1 resource)
    [
      set export_goods lput i export_goods
    ]

    set min_outputs lput (labor * item i i_desires) min_outputs
    let percentage (item i i_desires / sum i_desires)
    set desire_percentages lput percentage desire_percentages
    set required_labor required_labor + (item i min_outputs / item 0 resource)

    set i i + 1
  ]

  if(debug)
  [
    show(word "Min outputs 1: " min_outputs)
    show (word "Desire Percentages: " desire_percentages)
    show (word "Labor required: " required_labor)
  ]

  if(length export_goods = 0)
  [
    report list 0 "No resource worth exporting"
  ]


  let remaining_labor (labor - required_labor)
  if(debug)
  [
    show (word "Labor remaining: " remaining_labor)
  ]
  let recalculating false
  while[remaining_labor < 0]
  [
    set recalculating true


    let labor_percentage (labor / required_labor)


    let n_desires []
    foreach i_desires [ x ->
      let desire x * labor_percentage
      set n_desires lput desire n_desires]


    set required_labor 0
    set i 0
    while [i < number_of_products]
    [
      set min_outputs replace-item i min_outputs (item i n_desires * labor)
      set required_labor required_labor + (item i min_outputs / item 0 item i labor_values)
      set i i + 1
    ]
    set required_labor round required_labor
    let new_percentages []

    foreach n_desires [x -> set new_percentages lput (x / sum n_desires) new_percentages]
    set remaining_labor labor - required_labor
    set desire_percentages new_percentages

    if(debug)
    [
      show "recalculating labor"
      show (word "Labor vs required Labor percentage: " labor_percentage)
      show (word "New desires: " n_desires)
      show (word "New min outputs: " min_outputs)
      show (word "New required labor: " required_labor)
      show (word "Labor: " labor)
      show (word "New remaining labor: " remaining_labor)
      show remaining_labor
    ]
  ]

  if(remaining_labor = 0)
  [
    report list 1 "Remaining labor = 0"
  ]

  let autarky_production []

  set i 0
  while [i < number_of_products]
  [
    set autarky_production lput (item i min_outputs + ((item i desire_percentages * remaining_labor) * item 0 item i labor_values)) autarky_production
    set i i + 1
  ]

  set export_goods sort-by [[x y] -> (item 1 item x labor_values ) < (item 1 item y labor_values) ] export_goods

  let budget remaining_labor * item 1 item (last export_goods) labor_values

  if(debug)
  [
    show (word "Production in autarky: " autarky_production)
    show (word "Ordered exports: " export_goods)
    show (word "Budget: " budget)
  ]

  set i 0
  let final_value 0
  while [i < number_of_products]
  [
    let product_budget budget * item i desire_percentages
    let product_purchase (product_budget / item 1 item i labor_values)
    let trade_output  (item i min_outputs + product_purchase)
    let final_number trade_output - item i autarky_production
    set final_value final_value + (final_number * item 0 item i labor_values)

    if(debug)
    [
      show (word "Resource: " item i resource_list)
      show (word "Product Budget: " product_budget)
      show (word "Amount purchased: " product_purchase)
      show(word "min_outputs: " min_outputs)
      show (word "Total output: " trade_output)
      show (word "Trade - Autarky: " final_number)
    ]

    set i i + 1

  ]

  let lowest first sort-by [[x y]-> (item 1 x - item 0 x) < (item 1 y - item 0 y) ] labor_values

  let H1 item 0 item (last export_goods) labor_values
  let H2 item 1 item (last export_goods) labor_values
  Let L1 item 0 lowest
  let L2 item 1 lowest
  let Rh remaining_labor * item (last export_goods) desire_percentages
  let Rl remaining_labor * item (position lowest labor_values) desire_percentages

  ifelse (final_value > 0)
  [
    report list 2 final_value
  ]
  [
    if( length export_goods = number_of_products)
      [
        report list 3 final_value
    ]
    if(debug)
    [
      show (word "H1: " H1 " H2: " H2 " L1: " L1 " L2: " L2 " Rh:  " Rh " Rl: " Rl )
      show (word "Left: " ((H2 * Rl * L1) / L2) " Right: "  ((Rl * L1 * L1) + ((H1 - 1) * Rh * H1)) " result: "(((H2 * Rl * L1) / L2) < ((Rl * L1 * L1) + ((H1 - 1) * Rh * H1))) )
    ]
    if(((H2 * Rl * L1) / L2) < ((Rl * L1 * L1) + ((H1 - 1) * Rh * H1)))
    [
      report (list 4 final_value)
    ]

    report (list 5 final_value recalculating)
  ]

end

to-report test2 [ D_x Dp_x D_y Dp_y x1 x2 y1 y2]
  let R (1 - ((D_x / x1) + (D_y / y1)))

  if (R = 0)
  [
    report 0
  ]
  let Lx R * Dp_x
  let Ly R * Dp_y
  let max_yx max (list x2 y2)

  let Tx  ((((Lx * max_yx) / x2) + D_x) * x1)
  let Ty  ((((Ly * max_yx) / y2) + D_y) * y1)
  let Ax  (((Lx * x1) + D_x) * x1)
  let Ay  (((Ly * y1) + D_y) * y1)

  let T1 Tx + Ty
  let A1 Ax + Ay


  ifelse( x2 > y2)
  [
    set Tx (Lx * x1)
    set Ty ((Ly * x2 * y1) / y2)
  ]
  [
    set Ty (Ly * y1)
    set Tx ((Lx * y2 * x1) / x2)
  ]

  set Ax (Lx * (x1 * x1))
  set Ay (Ly * (y1 * y1))

  let T2 Tx + Ty
  let A2 Ax + Ay

  let H1 0
  let H2 0
  Let L1 0
  Let L2 0
  let Rh 0
  let Rl 0

  ifelse(x2 > y2)
  [
    set H1 x1
    set H2 x2
    set L1 y1
    set L2 y2
    set Rh R * Dp_x
    set Rl R * Dp_y
  ]
  [
    set H1 y1
    set H2 y2
    set L1 x1
    set L2 x2
    set Rh R * Dp_y
    set Rl R * Dp_x
  ]

  let T3 (H2 * Rl * L1 )/ L2
  let A3 (Rl * (L1 * L1)) + ((H1 - 1) * (Rh * H1))

  let C1 T1 > A1
  let C2 T2 > A2
  let C3 T3 > A3

  let C4 C1 = C2
  let C5 C2 = C3

  let C6 C4 = C5

  if(debug and number_of_tests < 50)
  [
    show (word "T1: " T1 " A1: " A1 " Diff: " (T1 - A1) " Divide: " (T1 / A1))
    show (word "T2: " T2 " A2: " A2 " Diff: " (T2 - A2) " Divide: " (T2 / A2))
  ]

  ifelse (C6 != true)
  [
    report 1
  ]
  [
    report 2
  ]

end

to-report test3 [ D_x Dp_x D_y Dp_y x1 x2 y1 y2]

  let R (1 - ((D_x / x1) + (D_y / y1)))

  if (R = 0)
  [
    report 0
  ]

  let H1 0
  let H2 0
  Let L1 0
  Let L2 0
  let Rh 0
  let Rl 0

  let outstring ""

  let export_goods []
 if( x2 > x1 )
  [
    set export_goods lput x2 export_goods
  ]
  if(y2 > y1)
  [
    set export_goods lput y2 export_goods
  ]

  if(length export_goods = 0)
  [
    report 1
  ]

  let export_good max export_goods

  ifelse(export_good = x2)
  [
    set H1 x1
    set H2 x2
    set L1 y1
    set L2 y2
    set Rh R * Dp_x
    set Rl R * Dp_y
    set outstring (word outstring "Wood has the highest selling price: " H2)
  ]
  [
    set H1 y1
    set H2 y2
    set L1 x1
    set L2 x2
    set Rh R * Dp_y
    set Rl R * Dp_x
    set outstring (word outstring "Stone has the highest selling price: " H2)
  ]

  let T (H2 * Rl * L1 )/ L2
  let A (Rl * (L1 * L1)) + ((H1 - 1) * (Rh * H1))

  let H2>H1 false
  let L2>L1 false
  let L1>H1 false
  let Rl>Rh false


    ifelse( H2 > H1 )
    [
      set outstring (word outstring " H2: " H2 " is larger than H1: " H1)
      set H2>H1 true
    ]
    [
      set outstring (word outstring " H1: " H1 " is larger than H2: " H2)
      set H2>H1 false
    ]

    ifelse( L2 > L1 )
    [
      set outstring (word outstring " L2: " L2 " is larger than L1: " L1)
      set L2>L1 true
    ]
    [
      set outstring (word outstring " L1: " L1 " is larger than L2: " L2)
      set L2>L1 false
    ]

    Ifelse (L1 > H1)
    [
      set outstring (word outstring " L1: " L1 " is larger than H1: " H1)
      set L1>H1 true
    ]
    [
      set outstring (word outstring " H1: " H1 " is larger than L1: " L1)
      set L1>H1 false
    ]

    Ifelse (Rl > Rh)
    [
      set outstring (word outstring " Rl: " Rl " is larger than Rh: " Rh)
      set Rl>Rh true
    ]
    [
      set outstring (word outstring " Rl: " Rl " is larger than Rh: " Rh)
      set Rl>Rh false
    ]

  let success false
  if (T > A)
  [
    set success true
  ]

  report (list success  H2>H1 L2>L1 L1>H1 Rl>Rh outstring)

end

to-report test4 [labor labor_values i_desires]

  let minR nations.calculate_min_outputs labor_values i_desires labor

  let min_outputs item 0 minR

  let R item 1 minR

  let EX nations.find_export_good labor_values

  if(EX = false)
  [
    report list 0 "No resource worth exporting"
  ]

  if(R = 0)
  [
    report list 1 "No Labor to work with"
  ]

  let autarky_production nations.find_autarky_outputs R labor_values i_desires

  let trade_values nations.find_trade_value labor_values i_desires R EX

  let RS nations.find_trade_feasibility labor_values EX

  let final_value (sum trade_values - sum autarky_production)

  ifelse ((precision final_value 5 > 0) = RS)
  [
    report (list 2)
  ]
  [
   ;; if(debug)
    ;;[
      show (word "Labor values: " labor_values )
      show (word "Labor: " labor)
      show (word "Desires: " i_desires)
      show (word "Minimum outputs: " min_outputs)
      show (word "Autarky: " autarky_production)
      show (word "H2: " item 1 item EX labor_values )
      show (word "Trade Values: "trade_values)
      show (word "Right side: " RS)
      show(word "Final value: " final_value)
    ;;]

    report (list 3 final_value nations.find_trade_feasibility labor_values EX )
  ]

end

to-report test5 [labor_values idesires labor]

  let required_labor 0

  let i 0
  foreach idesires [ x ->
    let min_output x * labor
    set required_labor required_labor + (min_output / item 0 item i labor_values)
    set i i + 1
  ]

  let remaining_labor labor - required_labor

  while [ remaining_labor < 0 ]
  [
    let labor_diff labor / required_labor
    set required_labor 0
    set i 0
    while [i < number_of_products]
    [
      set idesires replace-item i idesires (item i idesires * labor_diff)
      let min_output labor * item i idesires
      set required_labor required_labor + (min_output / item 0 item i labor_values)
      set i i + 1
    ]

    set remaining_labor labor - round required_labor
  ]

  if(remaining_Labor = 0)
  [
    report 0
  ]

  let export_goods []
  let desire_percentages []
  set i 0
  foreach labor_values [ x ->
    set desire_percentages lput (item i idesires / sum idesires) desire_percentages
    if(item 1 x > item 0 x)
    [
      set export_goods lput i export_goods
    ]
    set i i + 1
  ]


  if(length export_goods < 1)
  [
    report 1
  ]

  set export_goods sort-by [[x y] -> item 1 item x labor_values > item 1 item y labor_values] export_goods

  let lowest 0
  set i 0
  while [i < number_of_products]
  [
    if (i != first export_goods)
    [
      set lowest item i labor_values
    ]
    set i i + 1
  ]

  let H1 item 0 item (first export_goods) labor_values
  let H2 item 1 item (first export_goods) labor_values

  Let L1 item 0 lowest
  let L2 item 1 lowest
  let Rh remaining_labor * item (first export_goods) desire_percentages
  let Rl remaining_labor * item (position lowest labor_values) desire_percentages

  let Right_side ((H2 * Rl * L1) / L2) > ((Rl * L1) + ((H1 - 1) * Rh))

  let Left_side nations.find_trade_feasibility labor_values first export_goods
  set Right_side H2 > L2
  if(debug)
  [
    show (word "Labor Values: " labor_values)
    show (word "H2: " H2)
    show (word "L2: " L2)
    show (word "Right side: " Right_side)
    show (word "Left side: " Left_side)
  ]


  ifelse (Right_side = Left_side)
  [
    report 2
  ]
  [
    ;;show ("HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!HERE!!!")
    report 3
  ]

end

to-report test6 [labor_values idesires labor]

  let minR nations.calculate_min_outputs labor_values idesires labor

  let min_outputs item 0 minR

  let R item 1 minR

  let EX nations.find_export_good labor_values

  if(EX = false)
  [
    report list 0 "No resource worth exporting"
  ]

  if(R = 0)
  [
    report list 1 "No Labor to work with"
  ]

  let autarky_production nations.find_autarky_outputs R labor_values idesires

  let trade_values nations.find_trade_value labor_values idesires R EX


  ;;2

  let req 0

  let i 0
  while [ i < number_of_products]
  [
    set req  req + ((labor * item i idesires) / item 0 item i labor_values)
    set i i + 1
  ]

  if( req > labor)
  [
    set i 0
    set Req 0
    while [ i < number_of_products]
    [
      let labor_percentage 0
      let j 0
      while [ j < number_of_products]
      [
        set labor_percentage labor_percentage + ((labor * item j idesires) / item 0 item j labor_values)
        set j j + 1
      ]

      let new_D (item i idesires * (labor / labor_Percentage) )
      set Req Req + (new_D * labor) / item 0 item i labor_values
      set i i + 1
    ]

  ]


  let R2 labor - Req

  if(debug)
  [
    show (word "Remaining Labor 1: " R " Remaining Labor 2: " R2)
  ]

  set i 0
  let autarky_2 0
  while [i < number_of_products]
  [
    set autarky_2 autarky_2 + (R2 * (item i idesires / sum idesires) * item 0 item i labor_values)
    set i i + 1
  ]

  if(Debug)
  [
    show (word "Autarky 1: " sum autarky_production " Autarky 2: " autarky_2)
  ]

  set i 0

  let EX2 []
  while [ i < number_of_products]
  [
    if( item 1 item i labor_values > item 0 item i labor_values)
    [
      set EX2 lput i EX2
    ]
    set i i + 1
  ]

  set EX2 sort-by [ [x y] ->
    item 1 item x labor_values > item 1 item y labor_values
  ] EX2

  let trade_value2 []
  let desire_percentages2 []
  set i 0
  while [ i < number_of_products]
  [
    let budget R2 * item 1 item (first EX2) labor_values
    set desire_percentages2 lput (item i idesires / sum idesires) desire_percentages2
    set trade_value2 lput (((budget * item i desire_percentages2 ) / item 1 item i labor_values) * item 0 item i labor_values) trade_value2
    set i i + 1
  ]


  let desire_percentages []
  foreach idesires [x -> set desire_percentages lput (x / sum idesires) desire_percentages]

  if(Debug)
  [
    show (word "R1: " R " R2: " R2)
    show (word "EX 1: " EX " EX 2: " EX2)
    show (word "Budget1: " (R * item 1 item EX labor_values) " Budget2: " (R2 * item 1 item (first EX2) labor_values))
    show (word "desire_percentages: " desire_percentages "desire_percentages 2: " desire_percentages2)
    show (word labor_values)
    show (word "Trade_values 1: " trade_values " Trade_values 2: " trade_value2)
    show (word "Trade_value 1: " sum trade_values " Trade_value 2: " sum trade_value2)
  ]


  ;;OK now we know that Formula and Method are the same up to this point

  let final_value (sum trade_values - sum autarky_production)

  ;;let LS trade_value2  >  autarky_2
  let Ls precision final_value 5 > 0

  let H item 1 item (first EX2) labor_values

  set i 0
  let top 0
  while [ i < number_of_products ]
  [
    let DP (item i idesires / sum idesires)
    set top top + (H / item 1 item i labor_values)
    set i i + 1
  ]
  let RS top > number_of_products
  if(Debug)
  [
    show (Word "LS: " LS " T1: " trade_value2 " A1 " autarky_2 "RS: " RS  " T2: " top " A2: " number_of_products)
  ]
  ifelse( RS = LS)
  [
    report (list 2)
  ]
  [
    show (Word "LS: " LS " T1: " trade_value2 " A1 " autarky_2 " Value: " final_value "RS: " RS " T2: " top " A2: " number_of_products)

    report(list 3)
  ]



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
to-report nations.calculate_min_outputs [labor_values idesires labor]

  ;;Step 1: Find how much each item is desired
  let min_outputs []
  let req_labor 0
  let i 0
  while [i < number_of_products]
  [
    set min_outputs lput (labor * item i idesires) min_outputs
    set req_labor req_labor + (item i min_outputs / (item 0 item i labor_values))
    set i i + 1
  ]

  let R (labor - round req_labor)
  ;;Step 2: Calculate outputs in autarky

  ifelse(R < 0)
  [
    if(debug)
    [
      show "Recalculating"
    ]
    let labor_difference labor / req_labor
    let ndesires []
    foreach idesires [ x ->
      set ndesires lput (x * labor_difference) ndesires
    ]

    report nations.calculate_min_outputs labor_values ndesires labor
  ]
  [
    if(debug)
    [
      show (word labor_values " " idesires " " labor)
      show (word min_outputs " " R)
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

  let budget (item 1 item EX labor_values * R)

  let desire_percentages []
  foreach idesires [x -> set desire_percentages lput (x / sum idesires) desire_percentages]

  let Trade_values []
  let i 0
  foreach labor_values [ x ->
    set Trade_values lput (((budget * item i desire_percentages) / item 1 x) * item 0 x ) Trade_values
    set i i + 1
  ]

  report Trade_values
end

to-report nations.find_international_prices [nat_prices]
  let inter_prices []
  let i 0

  while [i < number_of_products]
  [
    let inter_price 0

    let national_prices []

    foreach nat_prices [ x ->
      set national_prices lput item i x national_prices
    ]

    set national_prices sort national_prices

    ;;Then we find a mid_point
    let midpoint (length national_prices) / 2
    ifelse(midpoint mod 1 != 0) ;;If we have a midpoint in our list
    [
      set inter_price item (floor midpoint) national_prices ;;Make our international_price equal to the midpoint
    ]
    [
      set inter_price ((item midpoint national_prices + item (midpoint - 1) national_prices) / 2)
    ]

    set inter_prices lput inter_price inter_prices
    set i i + 1
  ]

  report inter_prices
end


;;How much do we consume of each resource?
;;This depends on how much we desire the resource, right?
;;This is very percentage based right now.
;;We add all desires together, and find how much of our labor should go into each resource.
;;But that does not work when we factor in export/import, because producing one resource can lead to production in another.
;;The only things a nation knows are
;; A) How much labor it has available
;; B) How much it's labor is worth domestically and internationally
;; C) How much it desires each product

;;Let us assume, as in the Ricardian model, that we want to use our labor most effectively
;;Initially, we are working towards having enough in each resource to fill our desire * labor quota of production.
;;Then, we check how much of the stuff is available on the international market.
;;If there is enough, great! we don't need to devote labor to that resource, we can use kapital for it
;;If there isn't, tough luck, we are gonna have to make up the difference ourselves, and buy the rest.
;;That is our baseline calculation, which will have leftover kapital

;;But how are we going to fill our market initially if the market does not own any resources of it's own?
;;We need to make offers for selling things before our calculation for buying things.
;;We can assume that we are going to need to locally own the same amount of an export resource as we normally would produce.
;;Easiest / only option might be for the market to have an initial stock of resources to purchase from?
;;That way we can do our import calculations, and then figure out how much labor we have left over.
;;That labor can then be logically distributed between our exportable goods to make sure we have enough of each of them-
;;That can then be spent logically distributed again to make a nice, fat profit off of them
;;That profit is our leftover kapital

;;Step 1: We need to figure out the minimum production and the target desires for each resource
;;Step 2: We produce that locally, and then we find how much labor we have left over
;;That leftover labor is what we can use to make profits ;P
;;Step 3: Find our export/import goods
;;Step 4: If we have 0 or less labor remaining, we need to make some decisions


;;Need to also recall comparative advantage
;;Or do we in this model now?


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

to-report nations.trade [inter_market]


  ;;Step 1: Find labor values
  let i 0

  let labor_values []
  while [ i < number_of_products]
  [
    let local_labor_value item i technology_levels * item i resource_values
    let international_labor_value item i technology_levels * item i last [international_prices] of inter_market

    set labor_values lput (list local_labor_value international_labor_value)  labor_values
    set i i + 1
  ]

  ;;Step 2: Find Min_outputs and remaining labor

  let minR nations.calculate_min_outputs labor_values desires last population_over_time
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
     let autarky_production nations.find_autarky_outputs R labor_values desires

    set i 0
    foreach min_outputs [ x ->
      set min_outputs replace-item i min_outputs (x + item i autarky_production)
      set i i + 1
    ]

    report (list false min_outputs 1)
  ]

  ;;Step 3: Find if the trade would be profitable
  ifelse( nations.find_trade_feasibility labor_values export_good)
  [

    let desire_percentages []
    foreach desires [ x -> set desire_percentages lput (x / sum desires) desire_percentages]

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
    let autarky_production nations.find_autarky_outputs R labor_values desires

    set i 0
    foreach min_outputs [ x ->
      set min_outputs replace-item i min_outputs (x + item i autarky_production)
      set i i + 1
    ]

    report (list false min_outputs 3)
  ]
end


to nations.value_calculation [inter_market]
  ;;Step 1: Find comparison between domestic labor and foreign labor

  let i 0

  let labor_efficiencies []
  let local_labor []
  let international_labor []
  while [ i < number_of_products]
  [
    let local_labor_value item i technology_levels * item i resource_values
    let international_labor_value item i technology_levels * item i last [international_prices] of inter_market
    set local_labor lput local_labor_value local_labor
    set international_labor lput international_labor_value international_labor
    let efficiency 0
    ifelse( local_labor_value != 0)
    [
      set efficiency international_labor_value / local_labor_value
    ]
    [
      set efficiency international_labor_value / 0.01
    ]
    set labor_efficiencies lput (list (item i resource_list) efficiency) labor_efficiencies
    set i i + 1
  ]

  show (word "Local labor values: " local_labor)
  show (word "International labor values: " international_labor)


  ;;Step 2: Find which goods are more efficient to export than import
  set i 0
  let export_goods []
  while [ i < number_of_products]
  [
    if( item 1 item i labor_efficiencies > 1)
    [
      set export_goods lput i export_goods
    ]
    set i i + 1
  ]

  show (word "Determined export_goods: " export_goods)

  ;;Step 3: Find Autarky production

end

to nations.baseline_value_calculation [inter_market]
  let i 0
  let outputs []

  let profits 0
  let expendses 0

  let minimum_desired_amounts []
  let required_labor []
  let export_goods[]
  let import_goods 0

  while [ i < number_of_products]
  [
    ;;Step 1:
    set minimum_desired_amounts lput (item i desires * last population_over_time) minimum_desired_amounts

    ;;Step 2:
    ;;We can't use less than a whole labor in production
    set required_labor lput  ceiling (item i minimum_desired_amounts / item i technology_levels) required_labor

    ;;Step 3:
    ;;Find items that the market pays more for than domestic purchases
    ifelse( (item i resource_values * item i technology_levels)  < (item i last [international_prices] of inter_market * item i technology_levels))
    [
      set export_goods lput i export_goods
    ]
    [
      if(item i resource_values > item i last [international_prices] of inter_market)
      [
        set import_goods import_goods + 1
      ]
    ]

    set i i + 1
  ]

  show minimum_desired_amounts
  show outputs
  show required_labor
  ;;If we don't have anything that we want to import or something to export, we do not trade. Simple as.
  ifelse(length export_goods < 1 or import_goods < 1)
  [
     let output_string ""
      set i 0
      while [i < number_of_products]
      [
        set output_string (word output_string  item i resource_list  ": "  item i outputs  ", Value: " (precision (item i outputs * item i resource_values)1) " ")
        set i i + 1
      ]
      show output_string
  ]
  [
    show "TRADE"
    let remaining_labor last population_over_time - sum required_labor
    show remaining_labor
    let remaining_output []
    ;;Step 4: Ideal outcome for profit making: remaining labor > 0
    ifelse (remaining_labor > 0)
    [
      set remaining_output nations.trade_calculations inter_market remaining_labor export_goods
      set i 0
      let profit 0
      while [ i < number_of_products]
      [
        show "Raw:"
        show (word (item i resource_list) ": Autarky: " (item i outputs) " With trade: " (item i minimum_desired_amounts + item i remaining_output) " increase: "((item i minimum_desired_amounts + item i remaining_output) - item i outputs))
        show "Money:"
        show (word (item i resource_list) ": Autarky: " (item i outputs * item i resource_values) " With trade: " ((item i minimum_desired_amounts + item i remaining_output) * item i resource_values )
          " increase: " (((item i minimum_desired_amounts + item i remaining_output) * item i resource_values ) - (item i outputs * item i resource_values)))
        set profit profit + ((item i minimum_desired_amounts + item i remaining_output) * item i resource_values)
        set i i + 1
      ]
      show word "Total value produced: " profit
    ]
    [
      show "Non sustainable" ;;WIP
    ]
  ]

  set i 0


end

to-report nations.trade_calculations [inter_market labor exports]
  ;;Step 1: Figure out how much of each resource we want extra, and how good we are at producing exports

  let export_production[]
  let export_value 0
  foreach exports [x ->
    set export_production lput (item x technology_levels / sum technology_levels) export_production
  ]

  set export_production normalize export_production
  let i 0
  while [i < length exports]
  [
    set export_value (item (item i exports) last [international_prices] of inter_market * item (item i exports) technology_levels) * item i export_production
    set i i + 1
  ]

  let outstring "Export production: "
   set i 0
  while [i < length export_production]
  [
    set outstring (word outstring item (item i exports) resource_list ": " item i export_production " ")
    set i i + 1
  ]

  show outstring


  let import_values []
  set i 0

  while [i < number_of_products]
  [
    set import_values lput (precision (item i desires / sum desires) 2) import_values
    set i i + 1
  ]

  set outstring "Import Values: "

  set i 0
  while [i < number_of_products]
  [
    set outstring (word outstring item i resource_list ": " item i import_values " ")
    set i i + 1
  ]
  show outstring



  ;;Step 2: Make money with our exports
  let profits 0
  set i 0
  while [i < length exports]
  [

    let product (floor (item i export_production * labor)) * item (item i exports) technology_levels

    ask inter_market [
      set profits profits + markets.sell_item (item i exports) product
    ]
    set i i + 1
  ]

  ;;Step 3: Buy more resources with that money
    let purchases []
    set i 0

  while [ i < number_of_products]
  [
    let budget (item i import_values * profits)

    ask inter_market [
      set purchases lput (markets.purchase i budget) purchases
    ]
    set i i + 1
  ]

  report purchases

end

;;Market functions------------------------------------------------------------------------------------------------------------------------------------------------

to markets.setup
  set international_resource_storage n-values number_of_products [read-from-string initial_market_resource_function]
  set initial_prices n-values number_of_products [(precision ((random-float 4) + 1) 2) * (precision ((random-float 0.99) + 0.01) 2)]
  set international_prices (list n-values number_of_products [0])
end

to markets.update
  let product_percentages []
  let desired_percentage 1

  let sum_storage 0
  let i 0
  while [ i < number_of_products]
  [
    set sum_storage (sum_storage + last item i international_resource_storage)
    set i i + 1
  ]

  ifelse (sum_storage != 0)
  [
    show ("ping")
    set i 0
    while [i < number_of_products]
    [
      set product_percentages lput (last item i international_resource_storage / (sum_storage)) product_percentages
      set i i + 1
    ]

    set desired_percentage 1 / number_of_products
  ]
  [
    show ("pong")
    set product_percentages n-values number_of_products [1]
    set desired_percentage 1
    ]
  ;;Case desired_percentage = product_percentage
  ;; x + (x * 0) = x -> Perfectly balanced
  ;;Case desired_percentage > product_percentage
  ;; x + x * y = 1 + y * x -> We want to buy more of the good so we increase it's price
  ;;Case desired_percentage < product_percentage
  ;; x + x * -y = 1 - y * x -> We want to sell more of the good, so we decrease it's price
  ;;This ought to work :)

  let new_prices []
  set i 0

  foreach initial_prices [ x ->
    let percentage_difference (desired_percentage - item i product_percentages)
    show percentage_difference
    set new_prices lput max (list (x  + (x * percentage_difference)) 0) new_prices
    set i i + 1
  ]
  show new_prices
  set international_prices lput new_prices international_prices
end


;;Inputs:
;;Sell_index: The index of the resource to be sold in Resource_list
;;Sell_amount: How much of the resource should be sold
;;Desire_percentages: How much each resource in play is desired by the nation in question
;;Output:
;;How much of each resource has been purchased
to-report markets.sell_and_purchase [sell_index sell_amount desire_percentages]

  let budget markets.sell_item sell_index sell_amount
  let output n-values number_of_products [0]

  let i 0
  foreach desire_percentages [ x ->
    let purchase_budget x * budget
    let purchase markets.purchase i purchase_budget
    set output replace-item i output (item i output + purchase)
    set budget budget
    set i i + 1
  ]

  report output
end

to-report markets.sell_item [index amount]
  let new_amount last (item index international_resource_storage) + amount
  let updated_storage lput new_amount item index international_resource_storage
  set international_resource_storage replace-item index international_resource_storage updated_storage
  report amount * item index last international_prices
end

to-report markets.purchase [index budget]
  let amount  (budget / item index last international_prices)
  let new_amount  last (item index international_resource_storage) - amount
  let updated_storage lput new_amount item index international_resource_storage
  set international_resource_storage replace-item index international_resource_storage updated_storage

  report  amount
end

;;Normalize
to-report normalize [to-normalize]
  let normalized[]
  foreach to-normalize [ x ->
    let total sum to-normalize
    let percent 100 / total
    set normalized lput (precision ((x * percent) / 100) 2) normalized
  ]

  report normalized
end
@#$#@#$#@
GRAPHICS-WINDOW
218
10
655
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
6
46
69
79
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

BUTTON
74
11
137
44
setup
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

INPUTBOX
142
12
211
72
runtime
100.0
1
0
Number

MONITOR
598
10
655
55
Year
year
0
1
11

SLIDER
6
83
201
116
number_of_nations
number_of_nations
2
10
4.0
1
1
Nations
HORIZONTAL

SLIDER
5
122
199
155
initial_wealth
initial_wealth
10
10000
310.0
100
1
$
HORIZONTAL

SLIDER
5
159
201
192
initial_population_max
initial_population_max
100
10000
10000.0
100
1
Pop
HORIZONTAL

SLIDER
6
237
203
270
number_of_products
number_of_products
2
10
4.0
1
1
Products
HORIZONTAL

SLIDER
5
198
203
231
initial_population_min
initial_population_min
100
1000
1000.0
100
1
Pop
HORIZONTAL

BUTTON
7
10
70
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

INPUTBOX
666
10
970
70
initial_market_resource_function
[0]
1
0
String

INPUTBOX
7
275
162
335
number_of_tests
1000000.0
1
0
Number

BUTTON
73
48
136
81
Test
test
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
6
339
109
372
debug
debug
1
1
-1000

CHOOSER
6
379
144
424
test_chooser
test_chooser
"Test 1" "Test 2" "Test 3" "Test 4" "Test 5" "Test 6"
3

PLOT
666
73
1275
376
Market values
Year
Value
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Wood" 1.0 0 -10146808 true "" "let value 0\n\nask markets [\n set value value + item 0 last international_prices\n]\n\nplot value"
"Stone" 1.0 0 -7500403 true "" "let value 0\n\nask markets [\n set value value + item 1 last international_prices\n]\n\nplot value"
"Iron" 1.0 0 -12895429 true "" "let value 0\n\nask markets [\n set value value + item 2 last international_prices\n]\n\nplot value"
"Copper" 1.0 0 -3844592 true "" "let value 0\n\nask markets [\n set value value + item 3 last international_prices\n]\n\nplot value"

PLOT
1279
73
1888
376
Market Purchases
Year
Items
0.0
100.0
-10000.0
10000.0
true
true
"" ""
PENS
"Wood" 1.0 0 -10146808 true "" "let amount 0\n\nask markets [\nset amount amount + last (item 0 international_resource_storage)\n]\n\nplot amount"
"Stone" 1.0 0 -7500403 true "" "let amount 0\n\nask markets [\nset amount amount + last (item 1  international_resource_storage)\n]\n\nplot amount"
"Iron" 1.0 0 -12895429 true "" "let amount 0\n\nask markets [\nset amount amount + last (item 2 international_resource_storage)\n]\n\nplot amount"
"Copper" 1.0 0 -3844592 true "" "let amount 0\n\nask markets [\nset amount amount + last (item 3 international_resource_storage)\n]\n\nplot amount"

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
