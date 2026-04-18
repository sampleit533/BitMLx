# BÁO CÁO ĐỒ ÁN: TRIỂN KHAI ỨNG DỤNG SMART CONTRACT CROSS-CHAIN THEO BITMLX/BITML TOOLCHAIN

## Thông tin chung

| Mục | Nội dung |
|---|---|
| Tên đề tài | Triển khai ứng dụng smart contract cross-chain theo BitMLx/BitML toolchain trên mô hình UTXO |
| Sinh viên thực hiện | [Điền họ và tên] |
| Mã số sinh viên | [Điền MSSV] |
| Lớp | [Điền lớp] |
| Giảng viên hướng dẫn | [Điền tên giảng viên] |
| Mã nguồn | Repository `BitMLx` |
| Công nghệ chính | Haskell, Racket, Python, Flask, Docker, Makefile, pytest |

---

## Danh mục hình ảnh

| Hình | Nội dung |
|---|---|
| Hình 1 | Tổng quan tài liệu BitMLx gốc |
| Hình 2 | Kiến trúc tổng thể của đồ án |
| Hình 3 | Pipeline biên dịch end-to-end |
| Hình 4 | So sánh số lượng giao dịch và độ sâu cây thực thi của 4 ứng dụng |

---

## Mục lục

1. Giới thiệu tổng quan
2. Bài toán và động cơ thực hiện đồ án
3. Cơ sở lý thuyết
4. Mục tiêu và phạm vi của đồ án
5. Tổng quan kiến trúc hệ thống
6. Cấu trúc mã nguồn của repository
7. Các tính năng và khả năng chính của ứng dụng
8. Pipeline biên dịch BitMLx/BitML end-to-end
9. Phân tích chi tiết 4 ứng dụng smart contract cross-chain
10. Ứng dụng web BitMLx Artifacts Viewer
11. Chức năng Try Contract
12. Hệ thống kiểm thử và xác minh kết quả
13. Kết quả artifacts và số liệu thống kê
14. Đánh giá ưu điểm, hạn chế và hướng phát triển
15. Hướng dẫn chạy chương trình và kịch bản thuyết trình
16. Kết luận

---

## 1. Giới thiệu tổng quan

Đồ án này xây dựng một hệ thống phục vụ việc đặc tả, biên dịch, kiểm thử và trực quan hóa các smart contract cross-chain trên các blockchain kiểu Bitcoin, cụ thể là Bitcoin và Dogecoin. Nền tảng trung tâm của đồ án là BitMLx, một ngôn ngữ đặc tả hợp đồng thông minh cross-chain ở mức cao. Từ một đặc tả BitMLx duy nhất, hệ thống có khả năng sinh ra hai hợp đồng BitML tương ứng cho hai blockchain đích, sau đó tiếp tục biên dịch các hợp đồng này thành artifacts ở mức giao dịch UTXO.

Điểm nổi bật của đồ án là repository không chỉ chứa mã nguồn compiler hoặc một vài ví dụ minh họa đơn lẻ. Thay vào đó, repository đã được tổ chức thành một hệ thống hoàn chỉnh gồm nhiều lớp: compiler, pipeline tự động, Docker, bộ test, artifacts đã biên dịch sẵn và giao diện web để trực quan hóa kết quả. Nhờ đó, người dùng có thể chạy lại quá trình biên dịch, kiểm chứng đầu ra, xem kết quả trên giao diện web và thử tạo hợp đồng mới dựa trên các template có sẵn.

Luồng xử lý tổng quát của hệ thống có thể tóm tắt như sau:

```text
BitMLx source code
        ↓
BitMLx compiler viết bằng Haskell
        ↓
Hai hợp đồng BitML dạng .rkt cho Bitcoin và Dogecoin
        ↓
BitML compiler chạy trên Racket
        ↓
Các file .balzac mô tả giao dịch UTXO
        ↓
Artifacts, thống kê, kiểm thử và giao diện web
```

![Hình 1. Trang đầu tài liệu BitMLx gốc](docs/images/bitmlx_paper_trang_1.png)

Hình trên được trích xuất từ file `bitmlx.pdf` trong repository. Đây là tài liệu nền tảng để giải thích cơ sở học thuật của đồ án.

---

## 2. Bài toán và động cơ thực hiện đồ án

Trong thực tế, tài sản số không chỉ tồn tại trên một blockchain duy nhất. Một người dùng có thể nắm giữ Bitcoin, một người khác có thể nắm giữ Dogecoin, và một ứng dụng tài chính phi tập trung có thể cần phối hợp nhiều loại tài sản trên nhiều blockchain khác nhau. Từ đó phát sinh nhu cầu xây dựng các hợp đồng cross-chain, tức là các hợp đồng có logic liên quan đồng thời đến nhiều blockchain.

Tuy nhiên, việc xây dựng smart contract cross-chain gặp nhiều khó khăn vì mỗi blockchain là một hệ thống độc lập. Giao dịch trên Bitcoin không tự động kéo theo giao dịch tương ứng trên Dogecoin. Nếu một giao thức cross-chain được thiết kế không cẩn thận, một bên có thể nhận được lợi ích trên chain này nhưng không thực hiện nghĩa vụ tương ứng trên chain khác.

Mô hình rủi ro chính mà đồ án quan tâm gồm:

- Giao dịch có thể bị trì hoãn.
- Giao dịch có thể bị sắp xếp lại thứ tự.
- Một bên có thể cố tình không thực hiện bước tiếp theo của giao thức.
- Một nhánh hoàn tiền hoặc hủy giao dịch có thể được ưu tiên trước khi nhánh chính hoàn tất.
- Các hành động trên hai chain có thể không được đồng bộ đúng thời điểm.

Nếu viết thủ công các giao thức này ở mức giao dịch UTXO, khả năng sai sót là rất cao. Vì vậy, đồ án lựa chọn hướng tiếp cận có hệ thống: dùng BitMLx để mô tả hợp đồng ở mức cao, sau đó để compiler tự động sinh ra các hợp đồng BitML và artifacts giao dịch tương ứng cho từng blockchain.

---

## 3. Cơ sở lý thuyết

### 3.1. Mô hình UTXO

Blockchain kiểu Bitcoin sử dụng mô hình UTXO, viết tắt của Unspent Transaction Output. Trong mô hình này, tài sản không được lưu như số dư trong một tài khoản toàn cục mà được biểu diễn bằng các đầu ra giao dịch chưa được chi tiêu. Khi muốn sử dụng tài sản, người dùng tạo giao dịch mới tham chiếu đến các UTXO cũ và tạo ra các UTXO mới.

Một UTXO thường đi kèm điều kiện chi tiêu. Một số điều kiện phổ biến gồm:

- Yêu cầu chữ ký số của một participant.
- Yêu cầu tiết lộ preimage của một giá trị băm.
- Yêu cầu chờ đến một mốc thời gian hoặc block height nhất định.
- Yêu cầu thỏa mãn một biểu thức logic cụ thể.

Vì đặc thù này, smart contract trên blockchain kiểu Bitcoin thường không phải là một chương trình chạy liên tục như trên mô hình account-based. Thay vào đó, logic hợp đồng được hiện thực thành một tập giao dịch và điều kiện chi tiêu được liên kết với nhau.

### 3.2. BitML

BitML là ngôn ngữ đặc tả smart contract cho blockchain kiểu Bitcoin. BitML giúp người lập trình mô tả logic hợp đồng ở mức cao hơn, sau đó compiler sẽ sinh ra các giao dịch tương ứng. Trong repository này, đầu ra BitML được biểu diễn dưới dạng file `.rkt` chạy với `#lang bitml`.

Sau khi có file `.rkt`, hệ thống tiếp tục dùng BitML compiler để sinh ra file `.balzac`. File `.balzac` là artifact mô tả các transaction, điều kiện chi tiêu và cấu trúc thực thi ở mức gần với mô hình UTXO hơn.

### 3.3. BitMLx

BitMLx mở rộng tư tưởng của BitML sang bối cảnh cross-chain. Thay vì viết riêng từng hợp đồng cho từng chain, người dùng mô tả một hợp đồng BitMLx duy nhất. Compiler BitMLx sẽ sinh ra một cặp hợp đồng BitML, một cho Bitcoin và một cho Dogecoin.

Các khái niệm quan trọng trong BitMLx gồm:

- `PriorityChoice (+>)`: biểu diễn lựa chọn có thứ tự ưu tiên giữa các nhánh thực thi.
- `Step secrets`: các bí mật gắn với từng bước hoặc từng nhánh của cây hợp đồng, dùng làm bằng chứng hành vi.
- `Compensation phase`: pha bồi thường cho bên trung thực nếu phát hiện hành vi lệch giữa các chain.
- `Collateral`: khoản tài sản khóa thêm nhằm đảm bảo khả năng bồi thường.
- `TimedPreconditions`: tập điều kiện ban đầu kèm thời điểm bắt đầu và khoảng thời gian chờ.

### 3.4. Ý nghĩa của cơ chế priority choice

Trong các giao thức cross-chain, không phải mọi nhánh thực thi đều có cùng mức ưu tiên. Một nhánh chính có thể là nhánh mong muốn, còn nhánh sau là nhánh fallback hoặc refund. BitMLx dùng toán tử `+>` để biểu diễn thứ tự đó. Ví dụ:

```haskell
contract =
    guardedContract1
    +> guardedContract2
    +> WithdrawAll pA
```

Ý nghĩa là hệ thống ưu tiên thực thi `guardedContract1`. Nếu nhánh này không thể thực hiện sau một khoảng thời gian, hệ thống chuyển sang `guardedContract2`. Nếu các nhánh ưu tiên đều không thực hiện được, fallback cuối cùng đảm bảo tài sản không bị khóa vĩnh viễn.

### 3.5. Ý nghĩa của step secrets

Step secrets là một trong những cơ chế quan trọng nhất của BitMLx. Mỗi participant có các secret tương ứng với từng bước trong cây hợp đồng. Khi một participant thực hiện một nhánh ưu tiên, họ phải reveal step secret tương ứng. Việc reveal này tạo ra dấu vết có thể kiểm chứng.

Nếu participant chỉ thực hiện hành động trên một chain nhưng không đồng bộ trên chain còn lại, step secret đã bị lộ có thể được dùng làm bằng chứng để kích hoạt pha bồi thường. Vì vậy, step secrets đóng vai trò vừa là điều kiện thực thi vừa là cơ chế truy trách nhiệm.

---

## 4. Mục tiêu và phạm vi của đồ án

### 4.1. Mục tiêu kỹ thuật

Đồ án hướng đến các mục tiêu kỹ thuật sau:

- Biên dịch được các hợp đồng BitMLx sang BitML cho Bitcoin và Dogecoin.
- Sinh được artifacts `.rkt`, `.balzac`, `statistics.txt` và `*_depth.txt`.
- Chuẩn hóa môi trường build và test bằng Docker.
- Cung cấp các lệnh Makefile để người dùng chạy dễ dàng.
- Viết bộ integration test để kiểm tra pipeline đầu cuối.
- Xây dựng ứng dụng web để xem artifacts và thử biên dịch contract mới.

### 4.2. Mục tiêu học thuật

Về mặt học thuật, đồ án giúp làm rõ:

- Bài toán atomicity trong smart contract cross-chain.
- Rủi ro do scheduler hoặc miner có thể sắp xếp lại giao dịch.
- Cách BitMLx dùng priority choice, step secrets và compensation để giảm rủi ro.
- Chi phí phát sinh khi logic cross-chain được biên dịch xuống tập giao dịch UTXO.

### 4.3. Phạm vi

Phạm vi hiện tại của đồ án gồm:

- Hỗ trợ hai blockchain mục tiêu là Bitcoin và Dogecoin.
- Tập trung vào mô hình UTXO.
- Không triển khai giao dịch lên testnet hoặc mainnet.
- Tập trung vào pipeline biên dịch, artifacts, kiểm thử và trực quan hóa.
- Web app phục vụ demo và phân tích nội bộ, chưa hướng đến môi trường production.

---

## 5. Tổng quan kiến trúc hệ thống

Hệ thống được tổ chức thành nhiều lớp có nhiệm vụ rõ ràng. Lớp đầu tiên là mã nguồn BitMLx và compiler Haskell. Lớp thứ hai là pipeline tự động để biên dịch và sinh artifacts. Lớp thứ ba là thư mục `dist/bitmlx_artifacts` chứa kết quả đã build sẵn. Lớp thứ tư gồm hệ thống kiểm thử và web app để quan sát, xác minh và tương tác với kết quả.

![Hình 2. Kiến trúc tổng thể của đồ án](docs/images/kien_truc_tong_the_bitmlx.png)

Từ sơ đồ trên có thể thấy repository không chỉ là một compiler. Nó là một hệ sinh thái nhỏ gồm:

- Bộ đặc tả hợp đồng.
- Bộ biên dịch.
- Bộ script vận hành.
- Bộ artifacts đã sinh.
- Bộ test xác minh.
- Giao diện web.

Việc tổ chức như vậy giúp đồ án có tính tái lập cao và thuận tiện cho giảng viên kiểm tra.

---

## 6. Cấu trúc mã nguồn của repository

Repository có các thư mục và file quan trọng sau:

| Đường dẫn | Vai trò |
|---|---|
| `vendor/BitMLx/` | Mã nguồn BitMLx compiler viết bằng Haskell |
| `vendor/BitMLx/src/Syntax/BitMLx.hs` | Định nghĩa cú pháp BitMLx |
| `vendor/BitMLx/src/Compiler.hs` | Entry point biên dịch BitMLx sang BitML |
| `vendor/BitMLx/src/Compiler/Settings.hs` | Cấu hình compiler cho Bitcoin và Dogecoin |
| `vendor/BitMLx/src/Compiler/StepSecrets.hs` | Sinh step secrets cho từng participant và từng node |
| `vendor/BitMLx/src/Compiler/WellFormed.hs` | Kiểm tra tính hợp lệ của contract |
| `vendor/BitMLx/src/Depth.hs` | Tính độ sâu cây thực thi |
| `vendor/BitMLx/app/Examples/` | Các hợp đồng mẫu viết bằng Haskell embedded DSL |
| `vendor/BitMLx/app/Main.hs` | Đăng ký và chạy các example |
| `vendor/bitml-compiler/` | BitML compiler viết bằng Racket |
| `scripts/` | Các script bootstrap, compile, gom artifacts và chạy Docker |
| `tests/test_bitmlx_pipeline.py` | Integration test cho 4 ứng dụng chính |
| `web/app.py` | Backend Flask của ứng dụng web |
| `web/templates/` | Giao diện HTML cho dashboard, detail và try contract |
| `dist/bitmlx_artifacts/` | Artifacts đã biên dịch sẵn |
| `docker/Dockerfile` | Môi trường chạy tái lập |
| `Makefile` | Các lệnh chạy nhanh cho build, compile và test |

### 6.1. Lớp compiler Haskell

Phần compiler Haskell định nghĩa các cấu trúc của BitMLx như `PriorityChoice`, `Withdraw`, `WithdrawAll`, `Reveal`, `RevealIf`, `Auth`, `Split`, `WithdrawD` và `WithdrawAllD`. Đây là các khối xây dựng cơ bản để tạo hợp đồng cross-chain.

Compiler sử dụng `compileBitMLx` làm entry point. Hàm này nhận một `ContractAdvertisement` BitMLx và trả về hai `ContractAdvertisement` BitML, tương ứng với Bitcoin và Dogecoin. Điều này thể hiện rõ tính cross-chain: một đặc tả đầu vào được tách thành hai hợp đồng đầu ra cho hai blockchain.

### 6.2. Lớp script vận hành

Các script trong thư mục `scripts/` giúp biến compiler thành một pipeline có thể chạy thực tế. Thay vì người dùng phải nhớ nhiều lệnh Haskell, Racket và Python riêng lẻ, repository đã đóng gói các bước đó thành script:

- `bootstrap.sh` chuẩn bị môi trường.
- `bitmlx_pipeline.sh` chạy compile end-to-end.
- `build_4_apps.sh` biên dịch và gom 4 ứng dụng trọng tâm.
- `docker_run.sh` chạy lệnh bên trong Docker container.

### 6.3. Lớp web app

Web app nằm trong thư mục `web/`. Backend dùng Flask, frontend dùng HTML, CSS và JavaScript thuần. Web app không biên dịch lại toàn bộ khi mở dashboard; thay vào đó, nó đọc artifacts đã có trong `dist/bitmlx_artifacts/`, phân tích nội dung file và render ra giao diện.

---

## 7. Các tính năng và khả năng chính của ứng dụng

Phần này trình bày chi tiết tất cả các khả năng mà repository và ứng dụng có thể thực hiện.

### 7.1. Biên dịch smart contract cross-chain từ BitMLx sang BitML

Ứng dụng có khả năng nhận một hợp đồng BitMLx được viết dưới dạng Haskell embedded DSL và biên dịch thành hai hợp đồng BitML riêng biệt:

- Một hợp đồng cho Bitcoin.
- Một hợp đồng cho Dogecoin.

Khả năng này là trung tâm của toàn bộ đồ án. Nó cho phép người dùng viết logic cross-chain một lần ở mức cao, sau đó để compiler sinh ra phần triển khai tương ứng cho từng blockchain.

### 7.2. Sinh artifacts ở nhiều mức trừu tượng

Sau khi biên dịch, hệ thống sinh ra nhiều loại file:

- File `.rkt`: biểu diễn hợp đồng BitML dưới dạng Racket.
- File `.balzac`: mô tả các giao dịch UTXO được sinh từ BitML compiler.
- File `*_depth.txt`: lưu độ sâu cây thực thi.
- File `statistics.txt`: lưu bảng thống kê gồm tên contract, số transaction, độ sâu cây và chỉ số thời gian logic.

Nhờ có nhiều mức artifacts, người dùng có thể kiểm tra hệ thống từ góc nhìn ngôn ngữ cấp cao đến góc nhìn giao dịch cấp thấp.

### 7.3. Tự động thay thế hash placeholders

Một số hợp đồng dùng secrets. Trong mã nguồn mẫu, hash có thể được đặt bằng placeholder như `__SOME_HASH__` hoặc `__HASH__PLACEHOLDER__`. Script `replace_hash.py` tự động thay các placeholder này bằng hash SHA-256 của chuỗi ngẫu nhiên.

Khả năng này giúp pipeline có thể chạy hoàn chỉnh mà không cần người dùng tự chuẩn bị hash thủ công cho từng secret.

### 7.4. Kiểm tra tính hợp lệ của hợp đồng

Compiler có lớp kiểm tra well-formedness. Lớp này giúp phát hiện các lỗi như:

- Participant được dùng trong contract nhưng không có deposit trong preconditions.
- Secret được dùng trong `Reveal` hoặc `RevealIf` nhưng chưa được khai báo.
- Tổng lượng coin phân bổ trong `Withdraw` không khớp với tổng tài sản của contract.
- Tổng lượng coin trong các nhánh `Split` không khớp với số dư cần chia.

Đây là tính năng quan trọng vì lỗi trong smart contract có thể dẫn tới mất tài sản hoặc khóa tài sản vĩnh viễn.

### 7.5. Sinh step secrets tự động

Module `Compiler/StepSecrets.hs` duyệt cây hợp đồng và sinh step secrets cho từng participant tại các node cần thiết. Tên secret được tạo theo nhãn đường đi trong cây, ví dụ dạng `StepSecret_A__L_`.

Tính năng này giúp compiler tự động bổ sung bằng chứng hành vi vào hợp đồng đầu ra mà người viết contract không cần tạo thủ công từng secret.

### 7.6. Tính độ sâu cây thực thi

Module `Depth.hs` tính độ sâu cây thực thi của hợp đồng BitML đầu ra. Chỉ số này được ghi vào file `*_depth.txt` và dùng trong test. Độ sâu càng lớn thường cho thấy hợp đồng càng phức tạp, có nhiều lớp rẽ nhánh, nhiều pha chờ hoặc nhiều nhánh con.

### 7.7. Biên dịch riêng từng example

File `vendor/BitMLx/app/Main.hs` hỗ trợ chạy một example cụ thể thông qua tham số dòng lệnh. Ví dụ:

```bash
stack run -- ReceiverChosenDenomination
```

Khả năng này giúp quá trình test và debug nhanh hơn vì không cần compile toàn bộ example mỗi lần.

### 7.8. Biên dịch toàn bộ example

Nếu không truyền tên example hoặc truyền chế độ `all` thông qua script, hệ thống có thể compile toàn bộ danh sách example đã đăng ký. Điều này phù hợp khi muốn kiểm tra toàn bộ compiler hoặc tạo lại toàn bộ output.

### 7.9. Gom artifacts để bàn giao

Script `build_4_apps.sh` tự động compile 4 ứng dụng trọng tâm và copy kết quả vào `dist/bitmlx_artifacts/`. Đây là tính năng quan trọng cho việc nộp bài, vì giảng viên có thể xem trực tiếp artifacts mà không cần build lại ngay từ đầu.

### 7.10. Kiểm thử pipeline đầu cuối

File `tests/test_bitmlx_pipeline.py` kiểm tra pipeline thực sự chạy thành công. Test không chỉ kiểm tra file tồn tại, mà còn đọc `.balzac` để xác minh số transaction cực đại và đọc `*_depth.txt` để xác minh độ sâu.

### 7.11. Trực quan hóa artifacts bằng web dashboard

Web app cung cấp dashboard tổng quan cho 4 ứng dụng. Người dùng có thể xem:

- số lượng smart contract,
- số blockchain mục tiêu,
- tổng số transaction,
- biểu đồ so sánh transaction và depth,
- thông tin từng app,
- participants và secrets được trích xuất.

### 7.12. Xem chi tiết từng hợp đồng và từng chain

Trang chi tiết của web app cho phép xem dữ liệu theo từng chain. Người dùng có thể so sánh file Bitcoin và Dogecoin của cùng một app, xem kích thước file, số transaction, participants, secrets và nội dung file.

### 7.13. Thử biên dịch contract mới từ template

Trang `Try Contract` cho phép người dùng chọn template, chỉnh sửa tên participant và số lượng deposit BTC/DOGE. Backend sẽ sinh file Haskell tạm thời, gọi Docker chạy pipeline, sau đó trả kết quả về giao diện.

### 7.14. Chạy trong môi trường Docker tái lập

Dockerfile cung cấp môi trường có sẵn Racket, Stack, Python, LLVM và các thư viện cần thiết. Điều này giúp giảm rủi ro "chạy được trên máy em nhưng không chạy được trên máy khác".

### 7.15. Tự động hóa bằng Makefile

Makefile cung cấp các lệnh ngắn gọn:

```bash
make docker-build
make bootstrap
make compile EXAMPLE=ReceiverChosenDenomination
make compile-all
make test
make clean
```

Nhờ vậy, người dùng không cần nhớ chi tiết Docker command hoặc các bước pipeline bên trong.

---

## 8. Pipeline biên dịch BitMLx/BitML end-to-end

Pipeline biên dịch là phần quan trọng nhất của hệ thống vì nó biến một contract ở mức đặc tả thành artifacts có thể kiểm tra.

![Hình 3. Pipeline biên dịch end-to-end](docs/images/pipeline_bien_dich_bitmlx.png)

### 8.1. Bước 1: Chuẩn bị môi trường

Script `scripts/bootstrap.sh` tạo Python virtual environment, cài `prettytable` và `pytest`, cài `bitml-compiler` vào Racket local package, sau đó chạy `stack setup` và `stack build` cho BitMLx compiler.

Mục tiêu của bước này là bảo đảm container có đầy đủ công cụ để compile và test.

### 8.2. Bước 2: Chạy BitMLx compiler

Script `scripts/bitmlx_pipeline.sh` chuyển vào thư mục `vendor/BitMLx`, dọn các output cũ, sau đó chạy:

```bash
stack run -- <ExampleName>
```

Nếu chạy thành công, compiler sinh ra:

- `<Example>_bitcoin.rkt`
- `<Example>_dogecoin.rkt`
- `<Example>_depth.txt`

### 8.3. Bước 3: Thay thế hash placeholders

Với mỗi file `.rkt`, pipeline gọi:

```bash
python replace_hash.py <file.rkt>
```

Script này thay placeholder bằng giá trị băm SHA-256. Nhờ đó, các secret trong hợp đồng có hash commitment hợp lệ để BitML compiler tiếp tục xử lý.

### 8.4. Bước 4: Sinh file Balzac

Sau khi file `.rkt` đã hợp lệ, pipeline gọi Racket:

```bash
racket <file.rkt> > <file.balzac>
```

Kết quả là file `.balzac`, trong đó có các khai báo transaction như `transaction T1`, `transaction T2`, v.v.

### 8.5. Bước 5: Sinh thống kê

Script `read_statistics.py` đọc các file output và tạo `statistics.txt`. Bảng thống kê gồm:

- tên contract,
- tổng số transaction,
- độ sâu cây giao dịch,
- chỉ số thời gian logic suy ra từ các mốc `after` trong contract.

Lưu ý quan trọng: cột `Time to execute` trong `statistics.txt` không nên được hiểu là thời gian chạy thực tế của chương trình trên máy. Trong implementation hiện tại, giá trị này được suy ra từ các biểu thức thời gian trong file `.rkt`.

### 8.6. Bước 6: Gom artifacts

Khi cần tạo bộ kết quả cho 4 ứng dụng trọng tâm, script `build_4_apps.sh` chạy pipeline lần lượt cho từng app và copy kết quả vào `dist/bitmlx_artifacts/<App>/`.

Mỗi app trong `dist` có đúng 6 file:

- file `.rkt` cho Bitcoin,
- file `.rkt` cho Dogecoin,
- file `.balzac` cho Bitcoin,
- file `.balzac` cho Dogecoin,
- file `*_depth.txt`,
- file `statistics.txt`.

---

## 9. Phân tích chi tiết 4 ứng dụng smart contract cross-chain

Repository tập trung vào 4 ứng dụng chính. Đây là phần quan trọng khi thuyết trình vì nó thể hiện hệ thống không chỉ chạy được về mặt kỹ thuật mà còn mô phỏng nhiều bài toán cross-chain khác nhau.

### 9.1. ReceiverChosenDenomination

#### 9.1.1. Mục đích

Ứng dụng này mô phỏng bài toán quyên góp đa đồng, trong đó người nhận được quyền chọn denomination muốn nhận. Đây là ví dụ tương đối đơn giản nhưng thể hiện rõ cơ chế priority choice và fallback.

#### 9.1.2. Participants và deposits

| Participant | Vai trò | Deposit ban đầu |
|---|---|---|
| `A` | Người quyên góp | `(1 BTC, 1 DOGE)` |
| `B` | Người nhận | `(0 BTC, 0 DOGE)` |

#### 9.1.3. Logic hợp đồng

Contract có ba nhánh:

1. Nếu `B` chọn nhánh đầu tiên, `B` nhận `1 BTC`, còn `A` nhận `1 DOGE`.
2. Nếu nhánh đầu tiên không được thực hiện, nhánh thứ hai cho phép `B` nhận `1 DOGE`, còn `A` nhận `1 BTC`.
3. Nếu cả hai nhánh đều không thực hiện, fallback `WithdrawAll pA` trả lại toàn bộ tài sản cho `A`.

#### 9.1.4. Khả năng được minh họa

- Minh họa `PriorityChoice (+>)`.
- Minh họa fallback để tránh khóa tài sản vĩnh viễn.
- Minh họa biên dịch một contract đơn giản sang hai chain.

### 9.2. TwoPartyAgreement

#### 9.2.1. Mục đích

Ứng dụng này mô phỏng thỏa thuận giữa hai bên thông qua cơ chế reveal secrets. Có thể xem đây là một dạng coin-toss hoặc điều kiện phân nhánh dựa trên dữ liệu bí mật do hai bên tiết lộ.

#### 9.2.2. Participants, deposits và secrets

| Participant | Vai trò | Deposit ban đầu | Secret |
|---|---|---|---|
| `A` | Bên thứ nhất | `(1 BTC, 1 DOGE)` | `a` |
| `B` | Bên thứ hai | `(0 BTC, 0 DOGE)` | `b` |

#### 9.2.3. Logic hợp đồng

Contract sử dụng `RevealIf ["a", "b"]` để yêu cầu cả hai secret được tiết lộ và điều kiện logic được thỏa mãn. Nếu điều kiện thứ nhất đúng, tài sản được phân phối theo nhánh thứ nhất. Nếu điều kiện thứ hai đúng, tài sản được phân phối theo nhánh thứ hai. Nếu không có nhánh hợp lệ, fallback trả tài sản về cho `A`.

#### 9.2.4. Khả năng được minh họa

- Minh họa cơ chế `RevealIf`.
- Minh họa xử lý secret commitment.
- Minh họa pipeline thay thế hash placeholder trước khi chạy BitML compiler.

### 9.3. MultichainPaymentExchange

#### 9.3.1. Mục đích

Ứng dụng này mô phỏng bài toán thanh toán qua dịch vụ đổi tiền cross-chain. Một khách hàng muốn thanh toán bằng BTC, người nhận có thể nhận DOGE, và một exchange service tham gia cung cấp thanh khoản theo tỷ giá cố định.

#### 9.3.2. Participants và deposits

| Participant | Vai trò | Deposit ban đầu |
|---|---|---|
| `C` | Customer | `(10 BTC, 0 DOGE)` |
| `R` | Receiver | `(0 BTC, 0 DOGE)` |
| `X` | Exchange | `(0 BTC, 100 DOGE)` |

#### 9.3.3. Logic hợp đồng

Contract có ba hướng xử lý:

1. Nhánh ưu tiên thứ nhất: `C` xác nhận thanh toán, `R` nhận `10 BTC`, `X` giữ `100 DOGE`.
2. Nhánh thứ hai: exchange thực hiện đổi tiền, `R` nhận `100 DOGE`, `X` nhận `10 BTC`.
3. Nhánh fallback: `C` lấy lại `10 BTC`, `X` giữ `100 DOGE`.

#### 9.3.4. Khả năng được minh họa

- Minh họa hợp đồng có 3 participant.
- Minh họa bài toán dịch vụ trung gian trong cross-chain payment.
- Cho thấy số transaction tăng khi số participant và số nhánh tăng.

### 9.4. MultichainLoanMediator

#### 9.4.1. Mục đích

Ứng dụng này mô phỏng bài toán vay cross-chain có mediator giám sát quá trình trả góp. Đây là ứng dụng phức tạp nhất trong 4 ứng dụng trọng tâm.

#### 9.4.2. Participants và deposits

| Participant | Vai trò | Deposit ban đầu |
|---|---|---|
| `B` | Borrower | `(3 BTC, 0 DOGE)` |
| `L` | Lender | `(0 BTC, 30 DOGE)` |
| `M` | Mediator | `(0 BTC, 0 DOGE)` |

#### 9.4.3. Logic hợp đồng

Contract kết hợp nhiều lớp `Split`, nhiều nhánh `+>` và các bước xác nhận bởi mediator. Một phần tài sản được đưa vào quá trình trả góp, trong khi các nhánh fallback bảo vệ các bên nếu quá trình không tiếp tục như kỳ vọng. Mediator có vai trò xác nhận hoặc điều phối các bước trả góp.

#### 9.4.4. Khả năng được minh họa

- Minh họa contract nhiều tầng.
- Minh họa tác động của `Split` lồng nhau.
- Minh họa sự gia tăng rất lớn của artifacts khi contract phức tạp.
- Cho thấy trade-off giữa tính an toàn cross-chain và chi phí giao dịch.

---

## 10. Ứng dụng web BitMLx Artifacts Viewer

Ứng dụng web là phần giúp kết quả của đồ án trở nên trực quan, dễ kiểm tra và dễ trình bày. Thay vì yêu cầu người xem mở từng file `.rkt`, `.balzac` hoặc `statistics.txt`, web app tự động đọc artifacts và render thành giao diện.

### 10.1. Backend Flask

Backend nằm trong file `web/app.py`. Ứng dụng Flask chạy ở port `5000` và cung cấp các route chính:

| Route | Chức năng |
|---|---|
| `/` | Hiển thị dashboard tổng quan |
| `/app/<app_name>` | Hiển thị chi tiết một ứng dụng |
| `/try` | Hiển thị giao diện thử contract |
| `/try/compile` | Nhận JSON, sinh contract mới và chạy pipeline |

### 10.2. Dashboard tổng quan

Trang `/` có các khả năng:

- Đọc danh sách 4 ứng dụng từ `APPS_INFO`.
- Gọi `get_app_data()` để gom thông tin từng ứng dụng.
- Hiển thị số lượng smart contract.
- Hiển thị số blockchain mục tiêu.
- Tính tổng số transaction.
- Vẽ biểu đồ so sánh transaction và depth.
- Hiển thị từng card ứng dụng kèm mô tả, thông số và chain badges.
- Cho phép chuyển sang trang chi tiết.

### 10.3. Trang chi tiết từng ứng dụng

Trang `/app/<app_name>` có các khả năng:

- Kiểm tra `app_name` có nằm trong danh sách hợp lệ hay không.
- Đọc `statistics.txt`.
- Đọc file depth.
- Đọc thông tin theo chain Bitcoin và Dogecoin.
- Tính kích thước file `.rkt` và `.balzac`.
- Đếm số transaction trong `.balzac`.
- Trích xuất participants từ `.rkt`.
- Trích xuất secrets từ `.rkt`.
- Hiển thị nội dung file artifact dưới dạng viewer có thể mở rộng hoặc thu gọn.

Nếu file quá lớn, backend cắt nội dung hiển thị ở mức 50.000 ký tự để tránh làm giao diện quá nặng. Đây là lựa chọn hợp lý vì file `MultichainLoanMediator` có kích thước trên 1 MB.

### 10.4. Các hàm parser trong backend

`web/app.py` có các hàm parser quan trọng:

| Hàm | Chức năng |
|---|---|
| `parse_statistics()` | Đọc bảng `statistics.txt` và trích xuất tên contract, transaction, depth, time metric |
| `parse_balzac_transactions()` | Dùng regex tìm `transaction Tn` và lấy chỉ số transaction lớn nhất |
| `parse_rkt_participants()` | Trích xuất participant từ file `.rkt` |
| `parse_rkt_secrets()` | Trích xuất secret từ file `.rkt` |
| `get_app_data()` | Tổng hợp toàn bộ dữ liệu của một app |
| `read_file_content()` | Đọc nội dung file artifact có kiểm tra path traversal |

### 10.5. Cơ chế an toàn khi đọc file

Backend có kiểm tra:

```python
if not file_path.resolve().is_relative_to(ARTIFACTS_DIR.resolve()):
    return None
```

Điều này giúp ngăn người dùng truyền đường dẫn kiểu `../../etc/passwd` để đọc file ngoài thư mục artifacts. Đây là một chi tiết nhỏ nhưng thể hiện tư duy an toàn khi xây dựng web app.

### 10.6. Frontend

Frontend dùng HTML, CSS và JavaScript thuần. Các template gồm:

- `index.html`: dashboard.
- `detail.html`: trang chi tiết.
- `try.html`: trang thử biên dịch contract.

Giao diện có bố cục rõ ràng, nền tối, card thống kê, badge chain, tag participant, tag secret và viewer cho file code.

---

## 11. Chức năng Try Contract

Chức năng `Try Contract` là điểm nổi bật vì cho phép người dùng tương tác với pipeline thay vì chỉ xem artifacts tĩnh.

### 11.1. Các template được hỗ trợ

Web app hỗ trợ các template:

| Template | Ý nghĩa |
|---|---|
| `SimpleExchange` | Hai bên hoán đổi tài sản trực tiếp |
| `ReceiverChosenDenomination` | Quyên góp đa đồng, người nhận chọn denomination |
| `MultichainPaymentExchange` | Thanh toán qua exchange service |
| `TwoPartyAgreement` | Hai bên thỏa thuận thông qua reveal condition |
| `MultichainLoanMediator` | Vay cross-chain có mediator |

### 11.2. Quy trình xử lý

Quy trình của `Try Contract` gồm:

1. Người dùng chọn template trên giao diện.
2. Frontend hiển thị form participant tương ứng.
3. Người dùng chỉnh sửa tên participant, deposit BTC và deposit DOGE.
4. Frontend gửi JSON đến route `/try/compile`.
5. Backend kiểm tra template có hợp lệ hay không.
6. Backend kiểm tra số lượng participant có khớp với template không.
7. Backend validate deposit là số nguyên không âm.
8. Backend gọi `generate_hs_source()` để tạo mã Haskell mới.
9. Backend ghi file `UserCustom.hs` tạm thời.
10. Backend patch tạm `Main.hs` để đăng ký `UserCustom`.
11. Backend gọi Docker chạy `./scripts/bitmlx_pipeline.sh UserCustom`.
12. Backend thu thập output, statistics, depth và các file sinh ra.
13. Backend khôi phục `Main.hs` ban đầu và xóa file tạm.
14. Frontend hiển thị trạng thái compile, log, statistics và nội dung file.

### 11.3. Khả năng tùy chỉnh participant

Người dùng có thể đổi tên participant. Backend dùng `_validate_name()` để lọc tên, chỉ giữ chữ và số, giới hạn tối đa 20 ký tự. Public key được tạo lại theo dạng `pk<name>`.

### 11.4. Khả năng tùy chỉnh deposit

Người dùng có thể chỉnh số lượng BTC và DOGE mà mỗi participant deposit. Backend đảm bảo giá trị deposit không âm. Sau đó, `generate_hs_source()` thay deposit trong preconditions và scale các tuple coin trong thân contract theo tổng deposit mới.

### 11.5. Giới hạn thời gian compile

Backend đặt timeout 300 giây cho quá trình compile. Nếu pipeline chạy quá lâu, API trả lỗi timeout. Đây là cơ chế cần thiết vì compile một contract lớn có thể tiêu tốn nhiều thời gian.

### 11.6. Ý nghĩa của Try Contract

Tính năng này chứng minh hệ thống có khả năng hoạt động như một môi trường thử nghiệm hợp đồng cross-chain. Người dùng không cần chỉnh mã Haskell thủ công mà vẫn có thể thử các biến thể đơn giản của contract.

---

## 12. Hệ thống kiểm thử và xác minh kết quả

### 12.1. Unit tests trong BitMLx compiler

Thư mục `vendor/BitMLx/test/` chứa các test cho compiler Haskell. Các nhóm test chính gồm:

- `TestWithdraw`
- `TestSplit`
- `TestPriorityChoice`
- `TestWithdrawD`
- `TestManyParticipantsWithdraw`
- `TestManyParticipantsPriorityChoice`
- `TestAuthorize`
- `TestReveal`
- `TestRevealIf`
- `TestAdvertisement`
- `TestStipulation`

Ngoài ra, có các test cho trường hợp contract không hợp lệ:

- `InconsistentWithdraw`
- `InconsistentSplit`
- `UncommitedSecret`
- `NoDeposit`

Điều này cho thấy compiler không chỉ sinh output trong trường hợp đúng, mà còn có kiểm tra lỗi trong trường hợp input sai.

### 12.2. Integration tests bằng pytest

File `tests/test_bitmlx_pipeline.py` kiểm tra pipeline đầu cuối cho 4 ứng dụng trọng tâm. Mỗi test thực hiện:

- Chạy `./scripts/bitmlx_pipeline.sh <Example>`.
- Kiểm tra file Bitcoin `.balzac` tồn tại.
- Kiểm tra file Dogecoin `.balzac` tồn tại.
- Kiểm tra file `*_depth.txt` tồn tại.
- Đọc `.balzac` để tìm transaction lớn nhất.
- So sánh số transaction và depth với giá trị kỳ vọng.

Các giá trị kỳ vọng hiện tại:

| Ứng dụng | Transaction kỳ vọng | Depth kỳ vọng |
|---|---:|---:|
| ReceiverChosenDenomination | 51 | 6 |
| TwoPartyAgreement | 51 | 6 |
| MultichainPaymentExchange | 207 | 9 |
| MultichainLoanMediator | 4098 | 27 |

### 12.3. Giá trị của kiểm thử

Bộ test giúp xác nhận rằng:

- Pipeline vẫn chạy được sau khi thay đổi code.
- Compiler sinh đủ artifacts.
- Artifacts không bị rỗng hoặc sai cấu trúc.
- Số lượng transaction không bị thay đổi ngoài dự kiến.
- Depth của hợp đồng vẫn đúng theo baseline.

Đây là bằng chứng quan trọng khi nộp đồ án vì giảng viên có thể chạy `make test` để kiểm chứng thay vì chỉ đọc báo cáo.

---

## 13. Kết quả artifacts và số liệu thống kê

### 13.1. Bảng thống kê tổng quan

| Ứng dụng | Participants | Số secret trong `.rkt` Bitcoin | Số transaction | Depth | Time metric |
|---|---:|---:|---:|---:|---:|
| ReceiverChosenDenomination | 2 | 8 | 51 | 6 | 51 |
| TwoPartyAgreement | 2 | 10 | 51 | 6 | 51 |
| MultichainPaymentExchange | 3 | 12 | 207 | 9 | 51 |
| MultichainLoanMediator | 3 | 18 | 4098 | 27 | 61 |

![Hình 4. So sánh số lượng giao dịch và độ sâu cây thực thi của 4 ứng dụng](docs/images/thong_ke_4_ung_dung.png)

Từ bảng và biểu đồ có thể thấy `MultichainLoanMediator` có độ phức tạp vượt trội so với ba ứng dụng còn lại. Đây là kết quả hợp lý vì contract này có nhiều lớp `Split`, nhiều nhánh ưu tiên và nhiều bước được mediator xác nhận.

### 13.2. Kích thước artifacts

| Ứng dụng | Bitcoin `.rkt` | Dogecoin `.rkt` | Bitcoin `.balzac` | Dogecoin `.balzac` |
|---|---:|---:|---:|---:|
| ReceiverChosenDenomination | 6.326 B | 6.328 B | 15.631 B | 15.635 B |
| TwoPartyAgreement | 6.558 B | 6.560 B | 18.533 B | 18.537 B |
| MultichainPaymentExchange | 34.372 B | 34.486 B | 68.241 B | 68.433 B |
| MultichainLoanMediator | 1.145.845 B | 1.145.977 B | 1.265.684 B | 1.264.787 B |

### 13.3. Nhận xét từ số liệu

Các số liệu cho thấy:

- Hai ứng dụng đầu tiên có số transaction thấp hơn nhiều vì logic đơn giản.
- `MultichainPaymentExchange` tăng lên 207 transaction do có thêm participant và vai trò exchange.
- `MultichainLoanMediator` sinh 4098 transaction, cho thấy chi phí của hợp đồng cross-chain phức tạp là rất lớn.
- Kích thước file `.balzac` thường lớn hơn file `.rkt` vì nó mô tả chi tiết hơn các giao dịch.
- Sự khác biệt giữa Bitcoin và Dogecoin trong cùng một app là nhỏ, vì hai chain đều thuộc nhóm Bitcoin-style và dùng mô hình UTXO tương tự.

---

## 14. Đánh giá ưu điểm, hạn chế và hướng phát triển

### 14.1. Ưu điểm

Đồ án có các ưu điểm chính:

- Có pipeline chạy được đầu cuối, từ BitMLx đến Balzac.
- Có Docker để tái lập môi trường.
- Có Makefile giúp thao tác đơn giản.
- Có integration test kiểm tra kết quả thực tế.
- Có artifacts đã gom sẵn để nộp và trình bày.
- Có web app giúp trực quan hóa kết quả.
- Có chức năng Try Contract để thử biến thể contract mới.
- Có số liệu cụ thể để phân tích trade-off giữa độ phức tạp và chi phí giao dịch.

### 14.2. Hạn chế

Một số hạn chế hiện tại:

- Hệ thống mới hỗ trợ hai chain là Bitcoin và Dogecoin.
- Chưa triển khai giao dịch lên testnet hoặc mainnet.
- Web app hiện phù hợp cho demo nội bộ, chưa phải sản phẩm production.
- Chức năng Try Contract mới hỗ trợ chỉnh sửa template có sẵn, chưa phải trình thiết kế contract tổng quát.
- File artifacts lớn có thể làm việc hiển thị trên web chậm nếu không cắt ngắn.
- Cột `Time to execute` dễ gây hiểu nhầm nếu không giải thích rõ là time metric logic.

### 14.3. Hướng phát triển

Các hướng phát triển khả thi:

- Mở rộng compiler để hỗ trợ nhiều blockchain UTXO hơn.
- Xây dựng trình thiết kế contract trực quan thay vì chỉ sửa template.
- Thêm mô phỏng malicious scheduler để minh họa rõ hơn rủi ro cross-chain.
- Vẽ cây thực thi trực tiếp trên web app.
- Xuất báo cáo PDF tự động từ artifacts.
- Tối ưu compiler để giảm số lượng transaction sinh ra.
- Bổ sung benchmark về thời gian compile thực tế và tài nguyên sử dụng.

---

## 15. Hướng dẫn chạy chương trình và kịch bản thuyết trình

### 15.1. Yêu cầu

Máy chạy cần có Docker. Các dependency còn lại như Haskell Stack, Racket và Python package được chuẩn bị trong container.

### 15.2. Build Docker image

```bash
make docker-build
```

### 15.3. Compile một ứng dụng cụ thể

```bash
make compile EXAMPLE=ReceiverChosenDenomination
```

Có thể thay `ReceiverChosenDenomination` bằng:

- `TwoPartyAgreement`
- `MultichainPaymentExchange`
- `MultichainLoanMediator`

### 15.4. Compile toàn bộ ứng dụng

```bash
make compile-all
```

### 15.5. Chạy test

```bash
make test
```

### 15.6. Gom artifacts cho 4 ứng dụng trọng tâm

```bash
IMAGE=blockchain-bitmlx:dev ./scripts/docker_run.sh "./scripts/bootstrap.sh && ./scripts/build_4_apps.sh"
```

### 15.7. Kịch bản thuyết trình đề xuất

Khi thuyết trình, nên đi theo trình tự sau:

1. Giới thiệu bài toán cross-chain và rủi ro khi các chain thực thi độc lập.
2. Giới thiệu BitMLx như một DSL giúp mô tả contract cross-chain ở mức cao.
3. Trình bày kiến trúc repository theo Hình 2.
4. Trình bày pipeline biên dịch theo Hình 3.
5. Giải thích 4 ứng dụng minh họa từ đơn giản đến phức tạp.
6. Trình bày số liệu ở Hình 4, nhấn mạnh sự tăng mạnh của transaction trong `MultichainLoanMediator`.
7. Demo web app: dashboard, trang chi tiết, nội dung `.rkt`, nội dung `.balzac`.
8. Demo `Try Contract`: chọn template, đổi deposit, chạy compile và xem kết quả.
9. Kết luận về ưu điểm, hạn chế và hướng phát triển.

### 15.8. Đoạn trình bày ngắn có thể sử dụng

Đồ án của em triển khai một pipeline hoàn chỉnh cho smart contract cross-chain theo BitMLx và BitML. Thay vì viết thủ công giao dịch cho từng blockchain, em dùng BitMLx để mô tả hợp đồng ở mức cao. Compiler sau đó sinh ra hai hợp đồng BitML tương ứng cho Bitcoin và Dogecoin, rồi BitML compiler tiếp tục sinh ra artifacts `.balzac` ở mức giao dịch UTXO. Repo cũng có Docker để tái lập môi trường, Makefile để chạy nhanh, pytest để kiểm tra pipeline và web app Flask để trực quan hóa kết quả. Bốn ứng dụng minh họa cho thấy khi logic cross-chain phức tạp hơn, số transaction và kích thước artifacts tăng rất mạnh, đặc biệt ở bài toán vay có mediator.

---

## 16. Kết luận

Đồ án đã xây dựng được một hệ thống tương đối hoàn chỉnh để nghiên cứu và trình diễn smart contract cross-chain trên mô hình UTXO. Từ một đặc tả BitMLx ở mức cao, hệ thống có thể biên dịch thành hợp đồng BitML cho Bitcoin và Dogecoin, tiếp tục sinh artifacts `.balzac`, tạo thống kê, chạy kiểm thử và hiển thị kết quả trên giao diện web.

Về mặt kỹ thuật, repository thể hiện đầy đủ các năng lực quan trọng: tự động hóa pipeline, đóng gói môi trường bằng Docker, kiểm thử đầu cuối, lưu trữ artifacts và trực quan hóa dữ liệu. Về mặt học thuật, đồ án giúp làm rõ các khái niệm như priority choice, step secrets, compensation và chi phí phát sinh khi triển khai logic cross-chain xuống mô hình UTXO.

Kết quả quan trọng nhất của đồ án là biến một chủ đề mang tính lý thuyết cao thành một hệ thống có thể chạy, kiểm tra, quan sát và thuyết trình được. Đây là nền tảng tốt để tiếp tục phát triển thành công cụ nghiên cứu hoặc demo sâu hơn cho các giao thức smart contract cross-chain.
