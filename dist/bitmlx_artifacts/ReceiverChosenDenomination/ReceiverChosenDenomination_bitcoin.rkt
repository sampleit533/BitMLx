#lang bitml

(debug-mode)

(participant "A" "pkA")
(participant "B" "pkB")

(contract
 (pre
  (deposit "A" 1 "A_deposit_Bitcoin")
  (deposit "B" 0 "B_deposit_Bitcoin")
  (secret "A" StepSecret_A__L_ "0887e29b0f0fd5fb9cc7e8e4ce75ea7660fa7ca766c9bd3dba76ec6e714b7c27")
  (secret "B" StepSecret_B__L_ "8c4a43b15c072431394e600179b103e9a55e886d5572e1af78997228302b3973")
  (secret "A" StepSecret_A__LL_ "b0f5dfd494828d03e0fb8b4e9341b2978fb3f6b6068d75e8ecfa58e6e08a1c43")
  (secret "B" StepSecret_B__LL_ "6263f707b81c1c783b52f5b2914e421f660d3b2cf47647915ef4b91ba53d4d3e")
  (secret "A" StepSecret_A__LRL_ "b22245ce4f501ec8c73f1608e878c75cc3bfa4d36d2bfc2a604e47ac7ef9332d")
  (secret "B" StepSecret_B__LRL_ "19dfa0147b6aa62d9b6e82c4a5becc831a570271fac85cd0ceb27e003e51c466")
  (secret "A" StartSecret_A "3820ccfebbaa07681a46576b17bef9fd8e552a311a0ed75002dbcc3802f065f0")
  (secret "B" StartSecret_B "ddfde44d31649a7d638b7c875d568f8dee1b499bff6e03720b44879bb696ff5f")
  )

 (choice
  (reveal (StepSecret_A__L_ StartSecret_A StartSecret_B) (choice
                                                          (auth "B" (reveal (StepSecret_A__LL_) (withdraw "B"))
                                                           )
                                                          (auth "B" (reveal (StepSecret_B__LL_) (withdraw "B"))
                                                           )
                                                          (after 21 (reveal () (choice
                                                                                (reveal (StepSecret_A__LL_) (withdraw "B"))
                                                                                (reveal (StepSecret_B__LL_) (withdraw "A"))
                                                                                (after 31 (reveal () (choice
                                                                                                      (reveal (StepSecret_A__LRL_) (withdraw "A"))
                                                                                                      (reveal (StepSecret_B__LRL_) (withdraw "A"))
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
                                                          (auth "B" (reveal (StepSecret_A__LL_) (withdraw "B"))
                                                           )
                                                          (auth "B" (reveal (StepSecret_B__LL_) (withdraw "B"))
                                                           )
                                                          (after 21 (reveal () (choice
                                                                                (reveal (StepSecret_A__LL_) (withdraw "B"))
                                                                                (reveal (StepSecret_B__LL_) (withdraw "A"))
                                                                                (after 31 (reveal () (choice
                                                                                                      (reveal (StepSecret_A__LRL_) (withdraw "A"))
                                                                                                      (reveal (StepSecret_B__LRL_) (withdraw "A"))
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
