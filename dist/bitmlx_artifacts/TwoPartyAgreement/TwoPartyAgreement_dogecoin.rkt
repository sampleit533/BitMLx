#lang bitml

(debug-mode)

(participant "A" "pkA")
(participant "B" "pkB")

(contract
 (pre
  (deposit "A" 1 "A_deposit_Dogecoin")
  (deposit "B" 0 "B_deposit_Dogecoin")
  (secret "A" a "3abdf958e057e6a1a899b4e2c68af94d643be1ee49d63b78b7115fe15a11fe0b")
  (secret "B" b "e5f3f95a97e385156e2e7ff550acabbd37ccae9344d7d7d5d17e3d2f40fc76e4")
  (secret "A" StepSecret_A__L_ "47550bd0817afbf2d5c7207ca7c26571cf58f988b4acc6439ff62e0f17463e6e")
  (secret "B" StepSecret_B__L_ "72e5d8d2117a8925cb54cbbfc2320a420865636bd3e43545bd73bdf7d4b38467")
  (secret "A" StepSecret_A__LL_ "b224a90ad8d6b0b15cf89cff559e82eca4d95382b5feb12d0b091506c882a5c4")
  (secret "B" StepSecret_B__LL_ "1ef477f5c4bd947baf26144b7feaf574493cbb69a42823068bf60637bfa33013")
  (secret "A" StepSecret_A__LRL_ "fe232aee37d1fe9e0818805a396308ca6ecad33790a2b16c847a000ecf299832")
  (secret "B" StepSecret_B__LRL_ "97943ef2e1d66f945290e7ba110631a44f0c532690d53a07e952599ecc2778c2")
  (secret "A" StartSecret_A "e59c211b567424abae47b1455101fb6750260e79cde76caf3be3d7a5fd8bfd2e")
  (secret "B" StartSecret_B "691ccacc960970f0740975fcfef7d14b33e311e23140f456e36ae95a0ad4b4f8")
  )

 (choice
  (reveal (StepSecret_A__L_ StartSecret_A StartSecret_B) (choice
                                                          (revealif (StepSecret_A__LL_ a b) (pred (and (between b 0 1) (= a b))) (withdraw "A"))
                                                          (revealif (StepSecret_B__LL_ a b) (pred (and (between b 0 1) (= a b))) (withdraw "A"))
                                                          (after 21 (reveal () (choice
                                                                                (reveal (StepSecret_A__LL_) (withdraw "B"))
                                                                                (reveal (StepSecret_B__LL_) (withdraw "A"))
                                                                                (after 31 (reveal () (choice
                                                                                                      (revealif (StepSecret_A__LRL_ a b) (pred (and (between b 0 1) (!= a b))) (withdraw "B"))
                                                                                                      (revealif (StepSecret_B__LRL_ a b) (pred (and (between b 0 1) (!= a b))) (withdraw "B"))
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
                                                          (revealif (StepSecret_A__LL_ a b) (pred (and (between b 0 1) (= a b))) (withdraw "A"))
                                                          (revealif (StepSecret_B__LL_ a b) (pred (and (between b 0 1) (= a b))) (withdraw "A"))
                                                          (after 21 (reveal () (choice
                                                                                (reveal (StepSecret_A__LL_) (withdraw "B"))
                                                                                (reveal (StepSecret_B__LL_) (withdraw "A"))
                                                                                (after 31 (reveal () (choice
                                                                                                      (revealif (StepSecret_A__LRL_ a b) (pred (and (between b 0 1) (!= a b))) (withdraw "B"))
                                                                                                      (revealif (StepSecret_B__LRL_ a b) (pred (and (between b 0 1) (!= a b))) (withdraw "B"))
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
