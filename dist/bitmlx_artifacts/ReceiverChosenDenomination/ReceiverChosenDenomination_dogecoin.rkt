#lang bitml

(debug-mode)

(participant "A" "pkA")
(participant "B" "pkB")

(contract
 (pre
  (deposit "A" 1 "A_deposit_Dogecoin")
  (deposit "B" 0 "B_deposit_Dogecoin")
  (secret "A" StepSecret_A__L_ "4f56c2a36fd57b66855aba5156e84a701a825d49f990a980dec0a37d80b9ce84")
  (secret "B" StepSecret_B__L_ "2ed93562ba8293db376dba36105180876e04261768a4b8df984c7db5512ec58f")
  (secret "A" StepSecret_A__LL_ "bf6f9febcd14516ecce52819966b08f2456e7ae7ad1b377fee10062bc47d9d89")
  (secret "B" StepSecret_B__LL_ "bef0d2aa7d590c33d5e12b93431ee761d786d19ccd1e9d7ce2acbd29582b9cf1")
  (secret "A" StepSecret_A__LRL_ "815a42adfa563cff6f4c51bfe41a9d6d427cc04b3ca3e0f76589c9c2ed3a3715")
  (secret "B" StepSecret_B__LRL_ "806e6c18cdc1bb375e96c91b96f24d464aa45f871dc9c6888028463ae74abe9f")
  (secret "A" StartSecret_A "8a3c7898f607420f5758f109628a3ef91720f3567da3bb6c7c39919531c3d4ea")
  (secret "B" StartSecret_B "bfb1f2431d6c8d8d569192925c7796f0da1fcd305aacce8215f67ad81c7abafc")
  )

 (choice
  (reveal (StepSecret_A__L_ StartSecret_A StartSecret_B) (choice
                                                          (auth "B" (reveal (StepSecret_A__LL_) (withdraw "A"))
                                                           )
                                                          (auth "B" (reveal (StepSecret_B__LL_) (withdraw "A"))
                                                           )
                                                          (after 21 (reveal () (choice
                                                                                (reveal (StepSecret_A__LL_) (withdraw "B"))
                                                                                (reveal (StepSecret_B__LL_) (withdraw "A"))
                                                                                (after 31 (reveal () (choice
                                                                                                      (reveal (StepSecret_A__LRL_) (withdraw "B"))
                                                                                                      (reveal (StepSecret_B__LRL_) (withdraw "B"))
                                                                                                      (after 41 (reveal () (choice
                                                                                                                            (reveal (StepSecret_A__LRL_) (withdraw "B"))
                                                                                                                            (reveal (StepSecret_B__LRL_) (withdraw "A"))
                                                                                                                            (after 51 (reveal () (withdraw "A"))
                                                                                                                             )
                                                                                                                            ))
                                                                                                       )
                                                                                                      ))
                                                                                 )
                                                                                ))
                                                           )
                                                          ))
  (reveal (StepSecret_B__L_ StartSecret_A StartSecret_B) (choice
                                                          (auth "B" (reveal (StepSecret_A__LL_) (withdraw "A"))
                                                           )
                                                          (auth "B" (reveal (StepSecret_B__LL_) (withdraw "A"))
                                                           )
                                                          (after 21 (reveal () (choice
                                                                                (reveal (StepSecret_A__LL_) (withdraw "B"))
                                                                                (reveal (StepSecret_B__LL_) (withdraw "A"))
                                                                                (after 31 (reveal () (choice
                                                                                                      (reveal (StepSecret_A__LRL_) (withdraw "B"))
                                                                                                      (reveal (StepSecret_B__LRL_) (withdraw "B"))
                                                                                                      (after 41 (reveal () (choice
                                                                                                                            (reveal (StepSecret_A__LRL_) (withdraw "B"))
                                                                                                                            (reveal (StepSecret_B__LRL_) (withdraw "A"))
                                                                                                                            (after 51 (reveal () (withdraw "A"))
                                                                                                                             )
                                                                                                                            ))
                                                                                                       )
                                                                                                      ))
                                                                                 )
                                                                                ))
                                                           )
                                                          ))
  (after 11 (reveal () (choice
                        (reveal (StepSecret_A__L_) (withdraw "B"))
                        (reveal (StepSecret_B__L_) (withdraw "A"))
                        (after 21 (reveal () (withdraw "A"))
                         )
                        ))
   )
  ))
