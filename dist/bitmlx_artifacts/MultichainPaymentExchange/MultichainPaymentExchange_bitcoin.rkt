#lang bitml

(debug-mode)

(participant "C" "pkC")
(participant "R" "pkR")
(participant "X" "pkX")

(contract
 (pre
  (deposit "C" 20 "C_deposit_Bitcoin")
  (deposit "R" 10 "R_deposit_Bitcoin")
  (deposit "X" 10 "X_deposit_Bitcoin")
  (secret "C" StepSecret_C__L_ "dcfdedc91aee1d0d71d3f9b5301b84bd10a56a718993e46338d15fb35d23a06d")
  (secret "R" StepSecret_R__L_ "4ed823e017d0c701027d9d2ba5651322fe886dcb103e6c1765f0101cf537a067")
  (secret "X" StepSecret_X__L_ "fc2a52070ec25f56a9260c848bb876950ea484f1f4c9c1e9188a4af8923dd88e")
  (secret "C" StepSecret_C__LL_ "2ce128f777599fb8c76c3d12f939984fc41f9b796bba3928c1678a364a4a291d")
  (secret "R" StepSecret_R__LL_ "bca8364bd86faea0521f13944c0337fc6833194d58602aed7863a17d7284deeb")
  (secret "X" StepSecret_X__LL_ "8419c6efe98bef4a4c2651db6a18dc398fd90bb538c3149c2d016861e427d5cf")
  (secret "C" StepSecret_C__LRL_ "06febf1f278dbfdfbe3ca3d053fe335f40a4ecbc3410e30a989eda2b5132f50b")
  (secret "R" StepSecret_R__LRL_ "495ddbdf48d2a46908c2ef8adee88a4a6d137fff496bedd89f8212d9f0afa3c7")
  (secret "X" StepSecret_X__LRL_ "ebce838cb02e90a3db40a722c60240e7427fe7577b8af34794181473b26c9049")
  (secret "C" StartSecret_C "bf95e9feb3e5f97ec335412e5ede649057d491f718c5bc4a22bc598223ea5794")
  (secret "R" StartSecret_R "1531fbf4e14896acf6976b13d40feead436ddb1a45a62e7428ed0c43b016c5c6")
  (secret "X" StartSecret_X "1ca0141b67ba2cf820a319b9d4bcd0de2a3746d2ef87bc4bf548af00ad1b4706")
  )

 (choice
  (reveal (StepSecret_C__L_ StartSecret_C StartSecret_R StartSecret_X) (choice
                                                                        (auth "C" (reveal (StepSecret_C__LL_) (split
                                                                                                                (10 -> (withdraw "C"))
                                                                                                                (20 -> (withdraw "R"))
                                                                                                                (10 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_R__LL_) (split
                                                                                                                (10 -> (withdraw "C"))
                                                                                                                (20 -> (withdraw "R"))
                                                                                                                (10 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_X__LL_) (split
                                                                                                                (10 -> (withdraw "C"))
                                                                                                                (20 -> (withdraw "R"))
                                                                                                                (10 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (after 21 (reveal () (choice
                                                                                              (reveal (StepSecret_C__LL_) (split
                                                                                                                            (20 -> (withdraw "R"))
                                                                                                                            (20 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_R__LL_) (split
                                                                                                                            (20 -> (withdraw "C"))
                                                                                                                            (20 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_X__LL_) (split
                                                                                                                            (20 -> (withdraw "C"))
                                                                                                                            (20 -> (withdraw "R")))
                                                                                                                          )
                                                                                              (after 31 (reveal () (choice
                                                                                                                    (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                   (10 -> (withdraw "C"))
                                                                                                                                                   (10 -> (withdraw "R"))
                                                                                                                                                   (20 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                   (10 -> (withdraw "C"))
                                                                                                                                                   (10 -> (withdraw "R"))
                                                                                                                                                   (20 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                   (10 -> (withdraw "C"))
                                                                                                                                                   (10 -> (withdraw "R"))
                                                                                                                                                   (20 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (after 41 (reveal () (choice
                                                                                                                                          (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                                         (20 -> (withdraw "R"))
                                                                                                                                                                         (20 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                                         (20 -> (withdraw "C"))
                                                                                                                                                                         (20 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                                         (20 -> (withdraw "C"))
                                                                                                                                                                         (20 -> (withdraw "R")))
                                                                                                                                                                       )
                                                                                                                                          (after 51 (reveal () (split
                                                                                                                                                                 (20 -> (withdraw "C"))
                                                                                                                                                                 (10 -> (withdraw "R"))
                                                                                                                                                                 (10 -> (withdraw "X")))
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
                                                                                                                (10 -> (withdraw "C"))
                                                                                                                (20 -> (withdraw "R"))
                                                                                                                (10 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_R__LL_) (split
                                                                                                                (10 -> (withdraw "C"))
                                                                                                                (20 -> (withdraw "R"))
                                                                                                                (10 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_X__LL_) (split
                                                                                                                (10 -> (withdraw "C"))
                                                                                                                (20 -> (withdraw "R"))
                                                                                                                (10 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (after 21 (reveal () (choice
                                                                                              (reveal (StepSecret_C__LL_) (split
                                                                                                                            (20 -> (withdraw "R"))
                                                                                                                            (20 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_R__LL_) (split
                                                                                                                            (20 -> (withdraw "C"))
                                                                                                                            (20 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_X__LL_) (split
                                                                                                                            (20 -> (withdraw "C"))
                                                                                                                            (20 -> (withdraw "R")))
                                                                                                                          )
                                                                                              (after 31 (reveal () (choice
                                                                                                                    (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                   (10 -> (withdraw "C"))
                                                                                                                                                   (10 -> (withdraw "R"))
                                                                                                                                                   (20 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                   (10 -> (withdraw "C"))
                                                                                                                                                   (10 -> (withdraw "R"))
                                                                                                                                                   (20 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                   (10 -> (withdraw "C"))
                                                                                                                                                   (10 -> (withdraw "R"))
                                                                                                                                                   (20 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (after 41 (reveal () (choice
                                                                                                                                          (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                                         (20 -> (withdraw "R"))
                                                                                                                                                                         (20 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                                         (20 -> (withdraw "C"))
                                                                                                                                                                         (20 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                                         (20 -> (withdraw "C"))
                                                                                                                                                                         (20 -> (withdraw "R")))
                                                                                                                                                                       )
                                                                                                                                          (after 51 (reveal () (split
                                                                                                                                                                 (20 -> (withdraw "C"))
                                                                                                                                                                 (10 -> (withdraw "R"))
                                                                                                                                                                 (10 -> (withdraw "X")))
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
                                                                                                                (10 -> (withdraw "C"))
                                                                                                                (20 -> (withdraw "R"))
                                                                                                                (10 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_R__LL_) (split
                                                                                                                (10 -> (withdraw "C"))
                                                                                                                (20 -> (withdraw "R"))
                                                                                                                (10 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (auth "C" (reveal (StepSecret_X__LL_) (split
                                                                                                                (10 -> (withdraw "C"))
                                                                                                                (20 -> (withdraw "R"))
                                                                                                                (10 -> (withdraw "X")))
                                                                                                              )
                                                                         )
                                                                        (after 21 (reveal () (choice
                                                                                              (reveal (StepSecret_C__LL_) (split
                                                                                                                            (20 -> (withdraw "R"))
                                                                                                                            (20 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_R__LL_) (split
                                                                                                                            (20 -> (withdraw "C"))
                                                                                                                            (20 -> (withdraw "X")))
                                                                                                                          )
                                                                                              (reveal (StepSecret_X__LL_) (split
                                                                                                                            (20 -> (withdraw "C"))
                                                                                                                            (20 -> (withdraw "R")))
                                                                                                                          )
                                                                                              (after 31 (reveal () (choice
                                                                                                                    (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                   (10 -> (withdraw "C"))
                                                                                                                                                   (10 -> (withdraw "R"))
                                                                                                                                                   (20 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                   (10 -> (withdraw "C"))
                                                                                                                                                   (10 -> (withdraw "R"))
                                                                                                                                                   (20 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                   (10 -> (withdraw "C"))
                                                                                                                                                   (10 -> (withdraw "R"))
                                                                                                                                                   (20 -> (withdraw "X")))
                                                                                                                                                 )
                                                                                                                    (after 41 (reveal () (choice
                                                                                                                                          (reveal (StepSecret_C__LRL_) (split
                                                                                                                                                                         (20 -> (withdraw "R"))
                                                                                                                                                                         (20 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_R__LRL_) (split
                                                                                                                                                                         (20 -> (withdraw "C"))
                                                                                                                                                                         (20 -> (withdraw "X")))
                                                                                                                                                                       )
                                                                                                                                          (reveal (StepSecret_X__LRL_) (split
                                                                                                                                                                         (20 -> (withdraw "C"))
                                                                                                                                                                         (20 -> (withdraw "R")))
                                                                                                                                                                       )
                                                                                                                                          (after 51 (reveal () (split
                                                                                                                                                                 (20 -> (withdraw "C"))
                                                                                                                                                                 (10 -> (withdraw "R"))
                                                                                                                                                                 (10 -> (withdraw "X")))
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
                                                     (20 -> (withdraw "R"))
                                                     (20 -> (withdraw "X")))
                                                   )
                        (reveal (StepSecret_R__L_) (split
                                                     (20 -> (withdraw "C"))
                                                     (20 -> (withdraw "X")))
                                                   )
                        (reveal (StepSecret_X__L_) (split
                                                     (20 -> (withdraw "C"))
                                                     (20 -> (withdraw "R")))
                                                   )
                        (after 21 (reveal () (split
                                               (20 -> (withdraw "C"))
                                               (10 -> (withdraw "R"))
                                               (10 -> (withdraw "X")))
                                             )
                         )
                        ))
   )
  ))
