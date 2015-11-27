== README

####**1. HTTP Cache là gì**

Các bạn lập trình viên hẳn không xa lạ gì với khái niệm `Cache`. `CACHE` có nhiều loại và có thể áp dụng được từ cả hai phía : `Client` và `Server`. Hiện nay các trình duyệt đều có thể lưu trữ lại một phần hoặc toàn bộ thông tin của một trang web (như: `logo`, `banner`, `javascript`, `css`..). Những nội dung mà ít hoặc gần như không có sự thay đổi trong một thời gian dài. Việc này nhằm mục đích làm giảm thời gian và dung lượng mà client đòi hỏi server phải xử lý. Những thông tin như trên sẽ không cần phải lấy từ `server` về mà được load ngay trên trình duyệt của người dùng.

Cơ chế làm việc khi bạn truy cập vào trang `http://localhost:3000/home.html` như sau:

* 1, Trình duyệt: Gửi request lấy nội dung file home.html
* 2, Server : Tìm và đọc nội dung file home.html
* 3, Server: Trả về nội dung file hom.html
* 4, Trình duyệt: Hiển thị nội dung.

Mỗi lần bạn `refresh` lại trang thì bốn bước trên sẽ `lặp` lại một lần. Bạn hãy hình dung, nếu lúc đó website có 1.000 lượt truy cập đồng thời thì tốc độ tải trang web sẽ rất chậm.

Đối với các file như: `logo, javascript, css` bạn hoàn toàn có thể không có thay đổi gì trong một thời gian dài như vậy việc tải đi tải lại nhiều lần sẽ rất mất `thời gian` và `xử lý` của server.

Hôm nay tôi sẽ giới thiệu một số phương pháp giúp bạn có thể sử dụng `HTTP Cache` để lưu lại một số thông tin ngay trên trình duyệt của client.

Trong quá trình giới thiệu các phương pháp `HTTP Cache` tôi cũng sẽ giới thiệu song song Cách mà `Ruby on Rails` ứng dụng HTTP Cache trong ứng dụng web của mình.

####**2. Các Phương Pháp HTTP Cache và HTTP Cache trong ROR**

Trong một ứng dụng Web nói chung và ứng dụng Ruby on rails nói riêng, Chúng ta sẽ phải đặt ra câu hỏi `"Trang này có thay đổi gì trên controller không?"` và tìm câu trả lời cho câu hỏi đó.

Phương pháp tiếp cận đầu tiên là `Lần thay đổi cuối cùng - Last-Modified`

#####2.1 Last-Modified

Khi có request, Server sẽ trả về cho Trình duyệt thông tin của file đồng thời trả về thêm thời gian mà file này được cập nhật. Ví dụ bạn truy cập vào http://localhost:3000/posts trang index. Server sẽ trả về dánh sách Post cùng với `Last-Modified`

![1.png](https://viblo.asia/uploads/images/f817bb52ebf40f927e39324c5ca708c0aafde390/6c4dedd0754f10c4b97e8db3b7c807c3cfb6783a.png =441) 

Trình duyệt sẽ lưu thông tin này vào trong `Header`. Từ các lần truy cập sau trình duyệt sẽ gửi request kèm theo Header chứa thông tin này thông qua biến `If-Modified-Since`

Trình tự thực hiện như sau:

* 1, `Trình duyệt`: Gửi request lấy danh sách bài posts, và nội dung chỉ thay đổi sau ngày `23/11/2015 11:07:35 GMT`.
* 2, `Server`: tìm file và kiểm tra thời điểm câp nhật cuối cùng
* 3, `Server`: Trả về: Không có sự thay đổi nào sau thời điểm đó (HTML code `304 Not Modified`).
* 4, `Trình duyệt`: Hiển thị nội dung đã được lưu trong cache.

`Last-Modified` trong `Ruby on rails` sẽ được tạo ra bởi phương thức  `fresh_when` trong controller. Bây giờ chúng ta hãy cùng thử demo trên trang index của `posts_controller` nhé:

```ruby
def index
    @posts = Post.order_by_created_at.page params[:page]
    fresh_when last_modified: @posts.maximum(:updated_at)
end
``` 
Với `lần đầu` gửi request, server sẽ trả lại kết quả là danh sách posts và thời điểm Last-Modified (Trong ví dụ này mình lấy thời điểm cuối cùng update của bài post bất kỳ làm mốc)

![2.png](/uploads/images/f817bb52ebf40f927e39324c5ca708c0aafde390/e2cec23afb1deff17776ff8ceb4e77c73df4aa66.png =401) 


Bạn có thể thấy ở hình trên `status` trả về là `200` và kèm theo giá trị của `Last-Modified`.

Với request `tiếp theo` kết quả sẽ là:

![3.png](/uploads/images/f817bb52ebf40f927e39324c5ca708c0aafde390/4626f89c302cb243b23211ed68f39d58182548f2.png =383) 

`Status code` là `304` báo hiệu cho trình duyệt biết không có sự thay đổi nào từ phía server sau thời điểm `Last-Modified:Mon, 23 Nov 2015 01:04:25 GMT`.

Trình duyệt chỉ việc lấy danh sách bài posts được lưu trong cache trước đó.

Trong trường hợp tôi thêm 1 bài post và request lại thì server sẽ trả về danh sách bài post mới và trả về giá trị Last-Modified mới. 

Đó là cơ chế làm việc của phương pháp `Last-Modified`.

#####2.2 Etag

Với phương pháp `Last-Modified` chúng ta đã cải thiện đáng kể tốc độ của trong web, nhưng vẫn phải kết nối nhiều lần đến server, trên server vẫn phải xử lý thời gian cập nhật file. Trường hợp đồng hồ trên server và client lệch nhau thì file vẫn bị tải xuống ngoài ý muốn.

Giải pháp được đưa ra là sử dụng `Etag header`. `Etag` là mà chuỗi hash hoặc một chuỗi số được tạo ra bởi server cho người dùng mới truy cập lần đầu. Nếu user tiếp tục truy cập vào `URL` đó thì `Trình duyệt` sẽ gửi yêu cầu kèm theo mã `Etag`. Server sẽ chỉ trả về nội dung nếu file đã được cập nhật (dù chỉ 1 byte).

Dùng `Etag trong ROR `

Kể từ rails 4 chúng ta đã có thể cache các file `js, css` với `turbolinks`. Gem này cũng ứng dụng Etag để cache.

![4.png](/uploads/images/f817bb52ebf40f927e39324c5ca708c0aafde390/98137bbda447a1e02a11ab287d731b24287d8c64.png =912) 

Cùng xem giá trị  `Etag:"d885a0a66bd595c10edb24f8879f94e334d88be0730c4d7c7a7b57c731c09037"`

và chuỗi hash được `genarate` ra ở cuối file `css` nhé

`application.self-d885a0a66bd595c10edb24f8879f94e334d88be0730c4d7c7a7b57c731c09037.css`

nó trung khớp với nhau đúng không nào?

Khi bạn sửa bất kỳ thứ gì liên quan đến `application.css` và request lại trang thì chuỗi này mới thay đổi.

Sau đây mình sẽ sử dụng Etag để cache kết quả trả về từ request danh sách bài post nhé.

```ruby
def index
    @posts = Post.order_by_created_at.page params[:page]
    # fresh_when last_modified: @posts.maximum(:updated_at)
    fresh_when etag: @posts
end

```

Thay thế `last_modified` bằng `etag` là được. 


Khi thực hiện request trình duyệt sẽ gửi yêu cầu kèm theo tham số  If-None-Match: "etag keys"

Response trả về status 200 cùng với mã Etag nếu là lần truy cập đầu tiêm. Với các lần truy cập tiếp theo sẽ trả về status code `304 Not Modified` 

![5.png](/uploads/images/f817bb52ebf40f927e39324c5ca708c0aafde390/84228b019055dd0e26f33b105322029d8e055da8.png =375) 

#####2.3 Expires

Sử dụng `Etag` vẫn đòi hỏi server phải kiểm tra xem file có thay đổi nội dung không. `Expires` loại bỏ nhược điểm này bằng cách server sẽ gửi luôn `thời gian hết hạn` của cache để thông báo rằng nội dung file sẽ không thay đổi cho đến thời điểm expires. Từ thời điểm này đến hết thời điểm expires trình duyệt cứ lấy cache mà dùng. Đừng request lên server nữa.

Không có kết nối `Browser - Server`. `Browser` tự kiểm tra nếu file còn thời hạn thì sử dụng luôn nội dung đã được cache. Điều này sẽ làm giảm bớt công việc của Server - dành thời gian làm việc khác. 

#####2.4 Max-age

Phương pháp `Expires` rất tuyệt vời bởi vì bạn không cần request đến server nữa. Nhưng nó vẫn còn nhược điểm là `TRình duyệt vẫn phải tính toán thời gian hết bạn của cache`. 


Giải pháp cho vấn đề này là Server sẽ truyền vào luôn `max-age - là thời gian chính xác cache sẽ hết hạn` thay vì thời điểm sẽ hết hạn.

```
Cache-Control: public | private | no-cache, max-age = n 
```

Giá trị `max-age` được tính bằng giây

`Public`: file có thể được cache bởi proxy hoặc các máy chủ trung gian

`Private`: file có giá trị khác nhau cho từng người sử dụng. Browser có thể cache, nhưng các proxy không được cache.

`No-cache`: Browser và Proxy không được cache file này.

`ROR` cho phép bạn làm điều này với phương thức `expires_in`

```ruby
def index
    @posts = Post.order_by_created_at.page params[:page]
    expires_in 2.minutes
    # fresh_when last_modified: @posts.maximum(:updated_at)
    fresh_when etag: @posts
end

```
Sau 2 phút cache sẽ hết hạn và Trình duyệt sẽ request thẳng đến server.

![6.png](/uploads/images/f817bb52ebf40f927e39324c5ca708c0aafde390/cf0af6e72ea04855d6ee134c03148dfbda750cfd.png =259) 

#####**Chú ý:**

- Ruby on rails cho phép bạn kết hợp các phương pháp cache này với nhau

ví dụ: kết hợp `last_modified và etag`

```ruby
def index
    @posts = Post.order_by_created_at.page params[:page]
    expires_in 2.minutes
    fresh_when last_modified: @posts.maximum(:updated_at), etag: @posts
end

```

- Trường hợp bạn sửa thông tin của một bảng con bảng posts. 
ví  dụ: 1 post có nhiều tags. Bạn sửa thông tin bảng tags (
bảng con) thì:

```ruby
fresh_when last_modified: @posts.maximum(:updated_at)
```

là không có ý nghĩa vì load lại posts page sẽ ko có thay đổi gì. 
Ruby cho phép bạn khắc phục điều này bằng cách sử dụng  `:touch => true`
ở bảng con.

```ruby
belongs_to :company, :touch => true
```

như vậy thì sửa tag thì post liên quan đến nó cũng sẽ được cập nhật trường `updated_at`.

####**3. Kết luận**


Tối ưu hóa một website là một giai đoạn quan trọng và có ý nghĩa rất lớn trong việc cải thiện tốc độ trang web của bạn. 

Để tăng tốc một hệ thống bạn có thể nghĩ đến nhiều phương pháp và kết hợp đồng thời các phương pháp với nhau để có được kết quả khả quan nhất.

Ngoài việc refactor code, rút ngắn các câu query với việc thiết kế databases hợp lý, sử dụng các biện pháp cache trên server thì việc cache ngay trên client cũng là một biện pháp vô cùng hữu hiệu.

HTTP cache không quá phức tạp và cho kết quả nhanh chóng. 

Hi vọng bài viết này sẽ hữu ích với các bạn

Xin cảm ơn

Tham khảo sources code tại đây: https://github.com/HoangQuan/HTTP-cache-rails
