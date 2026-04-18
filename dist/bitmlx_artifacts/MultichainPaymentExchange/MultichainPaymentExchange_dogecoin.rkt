#lang bitml

(debug-mode)

(participant "C" "pkC")
(participant "R" "pkR")
(participant "X" "pkX")

(contract
 (pre
  (deposit "C" 100 "C_deposit_Dogecoin")
  (deposit "R" 100 "R_deposit_Dogecoin")
  (deposit "X" 200 "X_deposit_Dogecoin")
  (secret "C" StepSecret_C__L_ "deecb5bef4d202d72568b80360257ca32680938cf133740db30634d0134b8870")
  (secret "R" StepSecret_R__L_ "27b3d4500b42ddcd6ad4b0ad0f03199963753c7a8d56008b05b960aef120ed6c")
  (secret "X" StepSecret_X__L_ "31eb3f1a7654ffbe6e2c50d85cee3ce5996b9e3da5c96f8dfa3fa6aee53ae51e")
  (secret "C" StepSecret_C__LL_ "48063ddf2fa866ebee3b05e3e8697332b9ce34b059e3ea99580468b35601da9a")
  (secret "R" StepSecret_R__LL_ "54caf05855414464f92f3dc2ab5c0df6e8ebc62abb1fd3364b96f369ba3a2f93")
  (secret "X" StepSecret_X__LL_ "61d3c4ce7834e27ac7c36ed423979a1ae9694e0d2d563e34c0f2099124be0027")
  (secret "C" StepSecret_C__LRL_ "52f38413f71bec6515e4754366674f904f6bef0fbd34d9a349be736a965b6adf")
  (secret "R" StepSecret_R__LRL_ "28c8c52a467eeff3847598de7e89e4d0c8a8d3e4df9599ccb3fd769f1ec2e728")
  (secret "X" StepSecret_X__LRL_ "9d6a026335ae0a8a556f630312935d5c63d19d09553987a508a46be87b8cd1be")
  (secret "C" StartSecret_C "14107ff3b19a890f53a99342c1914458c8599115d79736d1de16231c4752cb6f")
  (secret "R" StartSecret_R "63930eb5721e5f89199e798d03eaa186a3f54ea66ad97b38e65984d6d340f5a5")
  (secret "X" StartSecret_X "7d2cfabcafa735414dd8122a945273bd1b87c30ec3e5454e54a60901e655531c")
  )

 (choice
  (reveal (StepSecret_C__L_ StartSecret_C StartSecret_R StartSecret_X) (choice
                                                                        (auth "C" (reveal (StepSecret_C__LL_) (split
                                                                                                                (100 -> (withdraw "C"))
                                                                                                                (100 -> (withdraw "R"))
                                                                                                                (200 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_R__LL_) (split
                                                                                                                (100 -> (withdraw "C"))
                                                                                                                (100 -> (withdraw "R"))
                                                                                                                (200 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_X__LL_) (split
                                                                                                                (100 -> (withdraw "C"))
                                                                                                                (100 -> (withdraw "R"))
                                                                                                                (200 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (after 21 (reveal () (choice
                                                                                              (reveal (StepSecret_C__LL_) (split
                                                                                                                            (200 -> (withdraw "R"))
                                                                                                                            (200 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_R__LL_) (split
                                                                                                                            (200 -> (withdraw "C"))
                                                                                                                            (200 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_X__LL_) (split
                                                                                                                            (200 -> (withdraw "C"))
                                                                                                                            (200 -> (withdraw "R")))
                                                                                                                          )
                                                                                              (after 31 (reveal () (choice
                                                                                                                    (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                   (100 -> (withdraw "C"))
                                                                                                                                                   (200 -> (withdraw "R"))
                                                                                                                                                   (100 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                   (100 -> (withdraw "C"))
                                                                                                                                                   (200 -> (withdraw "R"))
                                                                                                                                                   (100 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                   (100 -> (withdraw "C"))
                                                                                                                                                   (200 -> (withdraw "R"))
                                                                                                                                                   (100 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (after 41 (reveal () (choice
                                                                                                                                          (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                                         (200 -> (withdraw "R"))
                                                                                                                                                                         (200 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                                         (200 -> (withdraw "C"))
                                                                                                                                                                         (200 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                                         (200 -> (withdraw "C"))
                                                                                                                                                                         (200 -> (withdraw "R")))
                                                                                                                                                                       )
                                                                                                                                          (after 51 (reveal () (split
                                                                                                                                                                 (100 -> (withdraw "C"))
                                                                                                                                                                 (100 -> (withdraw "R"))
                                                                                                                                                                 (200 -> (withdraw "X")))
                                                                                                                                                               )
                                                                                                                                           )
                                                                                                                                          ))
                                                                                                                     )
                                                                                                                    ))
                                                                                               )
                                                                                              ))
                                                                         )
                                                                        ))
  (reveal (StepSecret_R__L_ StartSecret_C StartSecret_R StartSecret_X) (choice
                                                                        (auth "C" (reveal (StepSecret_C__LL_) (split
                                                                                                                (100 -> (withdraw "C"))
                                                                                                                (100 -> (withdraw "R"))
                                                                                                                (200 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_R__LL_) (split
                                                                                                                (100 -> (withdraw "C"))
                                                                                                                (100 -> (withdraw "R"))
                                                                                                                (200 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_X__LL_) (split
                                                                                                                (100 -> (withdraw "C"))
                                                                                                                (100 -> (withdraw "R"))
                                                                                                                (200 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (after 21 (reveal () (choice
                                                                                              (reveal (StepSecret_C__LL_) (split
                                                                                                                            (200 -> (withdraw "R"))
                                                                                                                            (200 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_R__LL_) (split
                                                                                                                            (200 -> (withdraw "C"))
                                                                                                                            (200 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_X__LL_) (split
                                                                                                                            (200 -> (withdraw "C"))
                                                                                                                            (200 -> (withdraw "R")))
                                                                                                                          )
                                                                                              (after 31 (reveal () (choice
                                                                                                                    (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                   (100 -> (withdraw "C"))
                                                                                                                                                   (200 -> (withdraw "R"))
                                                                                                                                                   (100 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                   (100 -> (withdraw "C"))
                                                                                                                                                   (200 -> (withdraw "R"))
                                                                                                                                                   (100 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                   (100 -> (withdraw "C"))
                                                                                                                                                   (200 -> (withdraw "R"))
                                                                                                                                                   (100 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (after 41 (reveal () (choice
                                                                                                                                          (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                                         (200 -> (withdraw "R"))
                                                                                                                                                                         (200 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                                         (200 -> (withdraw "C"))
                                                                                                                                                                         (200 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                                         (200 -> (withdraw "C"))
                                                                                                                                                                         (200 -> (withdraw "R")))
                                                                                                                                                                       )
                                                                                                                                          (after 51 (reveal () (split
                                                                                                                                                                 (100 -> (withdraw "C"))
                                                                                                                                                                 (100 -> (withdraw "R"))
                                                                                                                                                                 (200 -> (withdraw "X")))
                                                                                                                                                               )
                                                                                                                                           )
                                                                                                                                          ))
                                                                                                                     )
                                                                                                                    ))
                                                                                               )
                                                                                              ))
                                                                         )
                                                                        ))
  (reveal (StepSecret_X__L_ StartSecret_C StartSecret_R StartSecret_X) (choice
                                                                        (auth "C" (reveal (StepSecret_C__LL_) (split
                                                                                                                (100 -> (withdraw "C"))
                                                                                                                (100 -> (withdraw "R"))
                                                                                                                (200 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_R__LL_) (split
                                                                                                                (100 -> (withdraw "C"))
                                                                                                                (100 -> (withdraw "R"))
                                                                                                                (200 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_X__LL_) (split
                                                                                                                (100 -> (withdraw "C"))
                                                                                                                (100 -> (withdraw "R"))
                                                                                                                (200 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (after 21 (reveal () (choice
                                                                                              (reveal (StepSecret_C__LL_) (split
                                                                                                                            (200 -> (withdraw "R"))
                                                                                                                            (200 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_R__LL_) (split
                                                                                                                            (200 -> (withdraw "C"))
                                                                                                                            (200 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_X__LL_) (split
                                                                                                                            (200 -> (withdraw "C"))
                                                                                                                            (200 -> (withdraw "R")))
                                                                                                                          )
                                                                                              (after 31 (reveal () (choice
                                                                                                                    (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                   (100 -> (withdraw "C"))
                                                                                                                                                   (200 -> (withdraw "R"))
                                                                                                                                                   (100 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                   (100 -> (withdraw "C"))
                                                                                                                                                   (200 -> (withdraw "R"))
                                                                                                                                                   (100 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                   (100 -> (withdraw "C"))
                                                                                                                                                   (200 -> (withdraw "R"))
                                                                                                                                                   (100 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (after 41 (reveal () (choice
                                                                                                                                          (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                                         (200 -> (withdraw "R"))
                                                                                                                                                                         (200 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                                         (200 -> (withdraw "C"))
                                                                                                                                                                         (200 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                                         (200 -> (withdraw "C"))
                                                                                                                                                                         (200 -> (withdraw "R")))
                                                                                                                                                                       )
                                                                                                                                          (after 51 (reveal () (split
                                                                                                                                                                 (100 -> (withdraw "C"))
                                                                                                                                                                 (100 -> (withdraw "R"))
                                                                                                                                                                 (200 -> (withdraw "X")))
                                                                                                                                                               )
                                                                                                                                           )
                                                                                                                                          ))
                                                                                                                     )
                                                                                                                    ))
                                                                                               )
                                                                                              ))
                                                                         )
                                                                        ))
  (after 11 (reveal () (choice
                        (reveal (StepSecret_C__L_) (split
                                                     (200 -> (withdraw "R"))
                                                     (200 -> (withdraw "X")))
                                                   )
                        (reveal (StepSecret_R__L_) (split
                                                     (200 -> (withdraw "C"))
                                                     (200 -> (withdraw "X")))
                                                   )
                        (reveal (StepSecret_X__L_) (split
                                                     (200 -> (withdraw "C"))
                                                     (200 -> (withdraw "R")))
                                                   )
                        (after 21 (reveal () (split
                                               (100 -> (withdraw "C"))
                                               (100 -> (withdraw "R"))
                                               (200 -> (withdraw "X")))
                                             )
                         )
                        ))
   )
  ))
