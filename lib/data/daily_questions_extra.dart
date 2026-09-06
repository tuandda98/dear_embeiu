/// Additional daily questions appended AFTER the original bank
/// (`daily_questions.dart`). Kept in a separate file so the original indices
/// stay stable: the engine addresses questions by index in
/// `[...dailyQuestions, ...dailyQuestionsExtra]` and persists the used indices
/// per couple (`questionState/main.askedBankIds`), so entries here must ONLY
/// ever be APPENDED — never inserted, reordered or removed.
///
/// Same shape/rules as the original bank: `vi` + `en`, warm & light, no ICU
/// braces `{}` or markup.
library;

const List<Map<String, String>> dailyQuestionsExtra = <Map<String, String>>[
  // ── Ký ức tuổi thơ & gia đình (childhood & family) — 15 ────────────────────
  {
    'vi': 'Trò chơi tuổi thơ nào bạn muốn chơi lại một lần cùng người ấy?',
    'en': 'Which childhood game would you love to play once with your partner?',
  },
  {
    'vi': 'Ngày bé, ở nhà bạn hay được gọi bằng tên thân mật nào?',
    'en': 'As a kid, what pet name did your family call you at home?',
  },
  {
    'vi': 'Bữa cơm gia đình hồi nhỏ của bạn thường có món quen thuộc nào?',
    'en': 'What familiar dish was always on your family table growing up?',
  },
  {
    'vi': 'Người lớn nào thời thơ ấu đã dạy bạn điều bạn còn giữ tới giờ?',
    'en': 'Which grown-up from your childhood taught you something you still keep?',
  },
  {
    'vi': 'Căn phòng thời bé của bạn trông ra sao, bạn nhớ nhất góc nào?',
    'en': 'What did your childhood room look like, and which corner do you miss?',
  },
  {
    'vi': 'Những mùa hè tuổi nhỏ của bạn thường trôi qua như thế nào?',
    'en': 'How did your summers pass when you were little?',
  },
  {
    'vi': 'Có món đồ chơi cũ nào bạn vẫn nhớ rõ đến hôm nay không?',
    'en': 'Is there an old toy you still remember clearly today?',
  },
  {
    'vi': 'Ngày đầu tiên đi học, bạn còn nhớ mình đã sợ điều gì không?',
    'en': 'On your first day of school, do you remember what you were afraid of?',
  },
  {
    'vi': 'Trong nhà bạn có câu nói nào cả gia đình hay lặp lại không?',
    'en': 'Is there a saying your whole family keeps repeating at home?',
  },
  {
    'vi': 'Bạn muốn kể cho người ấy nghe kỷ niệm nào với ông bà mình?',
    'en': 'Which memory with your grandparents would you tell your partner?',
  },
  {
    'vi': 'Hồi nhỏ bạn hay trốn ở đâu mỗi khi muốn ở một mình?',
    'en': 'As a child, where did you hide when you wanted to be alone?',
  },
  {
    'vi': 'Có nếp sinh hoạt nào của gia đình bạn muốn giữ cho tổ ấm sau này?',
    'en': 'Is there a family routine you want to keep in your own home someday?',
  },
  {
    'vi': 'Lần đầu bạn thấy mình đã lớn là vào lúc nào?',
    'en': 'When was the first time you felt you had grown up?',
  },
  {
    'vi': 'Món quà nào hồi nhỏ khiến bạn vui nhất?',
    'en': 'What gift made you happiest as a child?',
  },
  {
    'vi': 'Nếu đưa người ấy về nơi bạn lớn lên, bạn muốn dẫn đi đâu trước?',
    'en': 'If you took your partner to where you grew up, where would you go first?',
  },

  // ── Ước mơ & tương lai (dreams & the future) — 15 ──────────────────────────
  {
    'vi': 'Nếu mỗi tháng có một kỳ nghỉ dài, chúng mình nên dùng nó thế nào?',
    'en': 'If you two had one long weekend every month, how would you use it?',
  },
  {
    'vi': 'Ở tuổi sáu mươi, bạn muốn ngày của chúng mình bắt đầu bằng điều gì?',
    'en': 'At sixty, how would you like your days together to begin?',
  },
  {
    'vi': 'Có thị trấn nhỏ nào bạn nghĩ hợp để chúng mình sống chậm lại?',
    'en': 'Is there a small town where you think you two could live more slowly?',
  },
  {
    'vi': 'Bạn muốn chúng mình cùng dành dụm cho điều gì trong năm tới?',
    'en': 'What would you like the two of you to save up for next year?',
  },
  {
    'vi': 'Bạn muốn ngôi nhà tương lai của chúng mình có mùi hương thế nào?',
    'en': 'What scent would you like your future home to have?',
  },
  {
    'vi': 'Bạn mong bạn bè nhớ đến chúng mình vì điều gì?',
    'en': 'What would you like your friends to know the two of you for?',
  },
  {
    'vi': 'Có công việc tay trái nào bạn muốn thử cùng người ấy không?',
    'en': 'Is there a side project you would like to try with your partner?',
  },
  {
    'vi': 'Bạn hình dung chuyến đi mừng mười năm bên nhau sẽ ra sao?',
    'en': 'How do you picture the trip for your tenth anniversary together?',
  },
  {
    'vi': 'Nếu chọn một mùa để tổ chức dịp trọng đại, bạn chọn mùa nào?',
    'en': 'If you chose one season for a big celebration, which would it be?',
  },
  {
    'vi': 'Ngày nghỉ hưu của chúng mình nên bắt đầu bằng chuyến đi tới đâu?',
    'en': 'Where should your retirement start with a trip to?',
  },
  {
    'vi': 'Có điều gì bạn muốn chúng mình thôi trì hoãn ngay từ tháng này?',
    'en': 'What would you like the two of you to stop putting off this month?',
  },
  {
    'vi': 'Năm sau nhìn lại, bạn mong chúng mình đã làm được điều gì?',
    'en': 'Looking back next year, what do you hope you two will have done?',
  },
  {
    'vi': 'Nếu có một cuốn album cho năm năm tới, trang đầu sẽ là gì?',
    'en': 'If you had an album for the next five years, what would page one be?',
  },
  {
    'vi': 'Bạn mong con đường sự nghiệp sẽ đưa chúng mình tới đâu?',
    'en': 'Where do you hope your careers will take the two of you?',
  },
  {
    'vi': 'Mỗi năm chúng mình nên có bao nhiêu chuyến đi, và kiểu đi nào?',
    'en': 'How many trips a year should you two take, and what kind?',
  },

  // ── Thói quen & đời thường (habits & everyday life) — 15 ───────────────────
  {
    'vi': 'Buổi sáng của bạn thường bắt đầu bằng việc gì đầu tiên?',
    'en': 'What is the very first thing you do each morning?',
  },
  {
    'vi': 'Bạn thích dọn dẹp cùng nhau vào lúc nào trong tuần?',
    'en': 'When in the week do you like tidying up together?',
  },
  {
    'vi': 'Trên đường đi làm, đầu bạn hay nghĩ về điều gì?',
    'en': 'On your way to work, what do you often think about?',
  },
  {
    'vi': 'Bạn có cách nhỏ nào giúp mình bình tĩnh lại khi căng thẳng?',
    'en': 'What small habit helps you calm down when you are stressed?',
  },
  {
    'vi': 'Chúng mình nên đặt điện thoại xuống vào khung giờ nào mỗi tối?',
    'en': 'What hour each evening should the two of you put the phones down?',
  },
  {
    'vi': 'Bạn hợp với dậy sớm hay thức khuya hơn?',
    'en': 'Are you more of an early riser or a night owl?',
  },
  {
    'vi': 'Đồ vật nào trong nhà bạn dùng mỗi ngày mà thầm thấy thích?',
    'en': 'Which everyday object at home do you quietly love?',
  },
  {
    'vi': 'Bạn hay quên điều gì nhất, và người ấy nhắc bạn kiểu gì?',
    'en': 'What do you forget most, and how does your partner remind you?',
  },
  {
    'vi': 'Việc nhà nào bạn thấy dễ chịu, việc nào bạn muốn nhường lại?',
    'en': 'Which chore do you find soothing, and which would you rather pass on?',
  },
  {
    'vi': 'Cuối ngày, điều gì khiến bạn thấy hôm nay đã trọn vẹn?',
    'en': 'At the end of a day, what makes it feel complete to you?',
  },
  {
    'vi': 'Bạn hay nghe gì khi làm việc nhà một mình?',
    'en': 'What do you listen to while doing chores alone?',
  },
  {
    'vi': 'Có tật nhỏ nào của bạn mà bạn nghĩ nên bỏ bớt không?',
    'en': 'Is there a small habit of yours you think you should drop?',
  },
  {
    'vi': 'Bạn sắp xếp tủ đồ theo kiểu gọn gàng hay tùy hứng?',
    'en': 'Do you keep your closet neat or a bit chaotic?',
  },
  {
    'vi': 'Nếu mỗi ngày có thêm một giờ, bạn sẽ dùng vào việc gì?',
    'en': 'If you had one extra hour each day, what would you spend it on?',
  },
  {
    'vi': 'Bạn dễ chịu hơn khi nhà thật yên tĩnh hay khi có tiếng nhạc?',
    'en': 'Do you feel better with a quiet home or with music playing?',
  },

  // ── Du lịch & trải nghiệm (travel & experiences) — 12 ──────────────────────
  {
    'vi': 'Chuyến đi đầu tiên bạn tự mình thực hiện là tới đâu?',
    'en': 'Where was the first trip you ever took on your own?',
  },
  {
    'vi': 'Đi cùng nhau, bạn chọn ngủ lều, homestay hay khách sạn?',
    'en': 'Camping, a homestay or a hotel when you travel together?',
  },
  {
    'vi': 'Món đồ nào bạn luôn nhét vào vali dù hiếm khi dùng tới?',
    'en': 'What do you always pack even though you rarely use it?',
  },
  {
    'vi': 'Bạn muốn cùng người ấy đi chuyến tàu đêm tới nơi nào?',
    'en': 'Where would you take an overnight train with your partner?',
  },
  {
    'vi': 'Trải nghiệm nào bạn từng thử một lần và muốn thử lại cùng nhau?',
    'en': 'What experience did you try once and want to repeat together?',
  },
  {
    'vi': 'Tới một nơi mới, bạn thích ghé chợ địa phương hay bảo tàng?',
    'en': 'Local markets or museums when you arrive somewhere new?',
  },
  {
    'vi': 'Có món quà lưu niệm nào bạn muốn mang về cho người ấy không?',
    'en': 'What souvenir would you love to bring home for your partner?',
  },
  {
    'vi': 'Ngày nghỉ, bạn chọn dậy sớm leo núi hay ngủ nướng thật đã?',
    'en': 'On a holiday, an early hike or a long lie-in?',
  },
  {
    'vi': 'Chuyến đi nào từng lệch hết kế hoạch mà lại vui bất ngờ?',
    'en': 'Which trip went off plan but turned out surprisingly fun?',
  },
  {
    'vi': 'Có môn thể thao mạo hiểm nào bạn muốn thử cùng người ấy?',
    'en': 'Which adventurous sport would you try with your partner?',
  },
  {
    'vi': 'Nếu được sống thử một tháng ở nước ngoài, chúng mình chọn đâu?',
    'en': 'If you two lived abroad for a month, where would you choose?',
  },
  {
    'vi': 'Bức ảnh du lịch nào của chúng mình bạn muốn in ra treo tường?',
    'en': 'Which travel photo of yours would you print and hang on a wall?',
  },

  // ── Ẩm thực & sở thích (food & hobbies) — 12 ───────────────────────────────
  {
    'vi': 'Nếu cả tuần chỉ được ăn một món, bạn chọn món gì?',
    'en': 'If you could eat only one dish for a week, what would it be?',
  },
  {
    'vi': 'Buổi sáng bạn nghiêng về cà phê, trà hay nước ép?',
    'en': 'Coffee, tea, or juice in the morning?',
  },
  {
    'vi': 'Quán ăn quen nào bạn muốn dẫn người ấy tới một lần?',
    'en': 'Which favorite eatery would you take your partner to once?',
  },
  {
    'vi': 'Bạn nấu món nào tự tin nhất?',
    'en': 'Which dish do you cook with the most confidence?',
  },
  {
    'vi': 'Vị nào hợp bạn hơn: ngọt, mặn hay cay?',
    'en': 'Which taste suits you best: sweet, salty or spicy?',
  },
  {
    'vi': 'Bữa ăn ngon nhất bạn từng có là ở đâu và với ai?',
    'en': 'Where and with whom was the best meal you ever had?',
  },
  {
    'vi': 'Có món nào bạn chỉ thèm khi trời mưa không?',
    'en': 'Is there a dish you only crave when it rains?',
  },
  {
    'vi': 'Bạn muốn học nấu món nào của quê người ấy?',
    'en': 'Which dish from your partner hometown would you learn to cook?',
  },
  {
    'vi': 'Sở thích nào khiến bạn quên cả thời gian?',
    'en': 'Which hobby makes you lose track of time?',
  },
  {
    'vi': 'Cuối tuần này, chúng mình thử một lớp học gì thì vui?',
    'en': 'What class would be fun for the two of you this weekend?',
  },
  {
    'vi': 'Cuốn sách hay bộ truyện nào bạn muốn người ấy đọc thử?',
    'en': 'Which book or series would you like your partner to try?',
  },
  {
    'vi': 'Bạn thích bữa ăn bày biện tươm tất hay giản dị nhanh gọn?',
    'en': 'Do you prefer a nicely set table or a quick simple meal?',
  },

  // ── Vui nhộn & nếu như (playful what-ifs) — 15 ─────────────────────────────
  {
    'vi': 'Nếu được làm trẻ con lại một ngày, chúng mình sẽ chơi gì?',
    'en': 'If you two were kids again for a day, what would you play?',
  },
  {
    'vi': 'Nếu người ấy là một món ăn, bạn nghĩ đó là món gì?',
    'en': 'If your partner were a dish, which one would they be?',
  },
  {
    'vi': 'Nếu chúng mình mở một kênh nội dung, chủ đề sẽ là gì?',
    'en': 'If you two started a channel, what would it be about?',
  },
  {
    'vi': 'Nếu thi nấu ăn với nhau, ai sẽ thắng và vì sao?',
    'en': 'If you two had a cook-off, who would win and why?',
  },
  {
    'vi': 'Nếu được đổi nghề trong một tuần, bạn muốn thử nghề gì?',
    'en': 'If you swapped jobs for a week, what would you try?',
  },
  {
    'vi': 'Nếu chúng mình là hai nhân vật hoạt hình, đó sẽ là ai?',
    'en': 'If you two were cartoon characters, who would you be?',
  },
  {
    'vi': 'Nếu nhà mình có một căn phòng bí mật, bên trong có gì?',
    'en': 'If your home had a secret room, what would be inside?',
  },
  {
    'vi': 'Nếu mỗi ngày chỉ được nhắn cho nhau ba từ, bạn chọn từ nào?',
    'en': 'If you could send only three words a day, which would you pick?',
  },
  {
    'vi': 'Nếu có một chú robot giúp việc, bạn giao nó làm gì trước?',
    'en': 'If you two had a helper robot, what job would you give it first?',
  },
  {
    'vi': 'Nếu được nuôi một loài vật lạ đời, chúng mình sẽ chọn con gì?',
    'en': 'If you two could keep an unusual animal, which would you pick?',
  },
  {
    'vi': 'Nếu chúng mình sống trong phim hoạt hình, cảnh mở đầu ra sao?',
    'en': 'If you lived in an animated film, how would the opening scene go?',
  },
  {
    'vi': 'Nếu người ấy đi thi tài lẻ, bạn nghĩ họ sẽ diễn tiết mục gì?',
    'en': 'If your partner entered a talent show, what act would they perform?',
  },
  {
    'vi': 'Nếu được đổi chỗ ở với ai đó một tuần, chúng mình chọn nhà ai?',
    'en': 'If you could swap homes with someone for a week, whose would it be?',
  },
  {
    'vi': 'Nếu có một ngày không internet, chúng mình sẽ làm gì cùng nhau?',
    'en': 'If you two had a day with no internet, what would you do?',
  },
  {
    'vi': 'Nếu chuyện tình của chúng mình là món tráng miệng, đó là món gì?',
    'en': 'If your love story were a dessert, what would it be?',
  },

  // ── Cảm xúc & lắng nghe (feelings & listening) — 15 ────────────────────────
  {
    'vi': 'Dạo này có điều gì làm bạn nặng lòng mà chưa kể ra không?',
    'en': 'Has anything been weighing on you lately that you have not shared?',
  },
  {
    'vi': 'Khi bạn im lặng, bạn muốn người ấy hiểu điều gì?',
    'en': 'When you go quiet, what would you like your partner to understand?',
  },
  {
    'vi': 'Bạn thấy dễ mở lòng nhất vào lúc nào trong ngày?',
    'en': 'At what time of day do you find it easiest to open up?',
  },
  {
    'vi': 'Có cảm xúc nào bạn thấy khó gọi tên không?',
    'en': 'Is there a feeling you find hard to name?',
  },
  {
    'vi': 'Khi lo lắng, bạn cần một cái ôm hay cần được lắng nghe hơn?',
    'en': 'When anxious, do you need a hug or to be heard more?',
  },
  {
    'vi': 'Điều gì khiến bạn thấy được tôn trọng trong một cuộc trò chuyện?',
    'en': 'What makes you feel respected in a conversation?',
  },
  {
    'vi': 'Bạn thường giấu sự mệt mỏi của mình bằng cách nào?',
    'en': 'How do you usually hide it when you are worn out?',
  },
  {
    'vi': 'Có lời nào bạn từng nghe mà buồn rất lâu không?',
    'en': 'Is there something you once heard that made you sad for a long time?',
  },
  {
    'vi': 'Khi vui đến mức khó giấu, bạn thể hiện ra sao?',
    'en': 'When you are really happy, how does it show?',
  },
  {
    'vi': 'Bạn muốn được an ủi bằng lời nói hay bằng sự có mặt lặng lẽ?',
    'en': 'Would you rather be comforted with words or with quiet company?',
  },
  {
    'vi': 'Dạo này điều gì làm bạn tự tin hơn về chính mình?',
    'en': 'What has made you feel more confident about yourself lately?',
  },
  {
    'vi': 'Có nỗi sợ nhỏ nào bạn muốn người ấy biết để hiểu bạn hơn?',
    'en': 'Is there a small fear you want your partner to know about?',
  },
  {
    'vi': 'Khi cần một khoảng lặng, bạn muốn người ấy làm gì?',
    'en': 'When you need some space, what would you like your partner to do?',
  },
  {
    'vi': 'Tuần này có chuyện gì khiến bạn thấy nhẹ nhõm hẳn không?',
    'en': 'Did anything bring you real relief this week?',
  },
  {
    'vi': 'Bạn nhận ra mình đang căng thẳng nhờ dấu hiệu nào?',
    'en': 'What sign tells you that you are getting stressed?',
  },

  // ── Biết ơn & những điều nhỏ (gratitude & small things) — 12 ───────────────
  {
    'vi': 'Hôm nay có điều nhỏ nào khiến bạn thấy mình may mắn?',
    'en': 'What small thing made you feel lucky today?',
  },
  {
    'vi': 'Hôm nay bạn muốn cảm ơn cơ thể mình vì điều gì?',
    'en': 'What would you thank your body for today?',
  },
  {
    'vi': 'Ngoài người ấy, tuần này bạn muốn cảm ơn ai?',
    'en': 'Besides your partner, who deserves a thank-you from you this week?',
  },
  {
    'vi': 'Tiếng động quen thuộc nào ở nhà khiến bạn thấy bình yên?',
    'en': 'Which familiar sound at home makes you feel at peace?',
  },
  {
    'vi': 'Bạn biết ơn điều gì ở quãng thời gian khó khăn đã đi qua?',
    'en': 'What are you grateful for in a hard time that has passed?',
  },
  {
    'vi': 'Có thứ nhỏ xíu nào bạn dùng mỗi ngày mà thầm biết ơn không?',
    'en': 'Is there a tiny thing you use daily and quietly appreciate?',
  },
  {
    'vi': 'Người ấy hay nói câu gì khiến bạn thấy như được tiếp sức?',
    'en': 'What does your partner say that gives you strength?',
  },
  {
    'vi': 'Bạn biết ơn điều gì ở nơi chúng mình đang sống?',
    'en': 'What are you grateful for about where the two of you live?',
  },
  {
    'vi': 'Hôm nay bạn thấy điều gì rất bình thường mà lại đẹp?',
    'en': 'What ordinary thing looked beautiful to you today?',
  },
  {
    'vi': 'Món đồ nào người ấy tặng mà bạn giữ gìn kỹ nhất?',
    'en': 'Which gift from your partner do you keep most carefully?',
  },
  {
    'vi': 'Ai là người đã dạy bạn cách yêu thương một ai đó?',
    'en': 'Who taught you how to care for someone you love?',
  },
  {
    'vi': 'Gần đây có ngày bình thường nào mà bạn thấy thật dễ chịu?',
    'en': 'Was there an ordinary day recently that felt really good?',
  },

  // ── Giao tiếp & cách yêu (communication & love styles) — 12 ────────────────
  {
    'vi': 'Bạn thích được khen riêng tư hay khen trước mặt mọi người?',
    'en': 'Do you like compliments in private or in front of others?',
  },
  {
    'vi': 'Có chuyện cần nói, bạn muốn nói ngay hay đợi lúc bình tĩnh?',
    'en': 'When something needs saying, do you speak up right away or wait?',
  },
  {
    'vi': 'Nhắn tin hay gọi điện hợp với bạn hơn?',
    'en': 'Do texts or calls suit you better?',
  },
  {
    'vi': 'Có cách nhắc nhở nào khiến bạn dễ tiếp nhận hơn không?',
    'en': 'Is there a way of being reminded that feels easier to accept?',
  },
  {
    'vi': 'Bạn muốn người ấy hỏi thẳng hay tự đoán ý bạn?',
    'en': 'Would you rather your partner ask directly or read between the lines?',
  },
  {
    'vi': 'Khi kể chuyện, bạn cần lời khuyên hay chỉ cần một người nghe?',
    'en': 'When you share, do you want advice or just a listener?',
  },
  {
    'vi': 'Câu hỏi nào giúp bạn dễ mở lòng nhất?',
    'en': 'Which question helps you open up most easily?',
  },
  {
    'vi': 'Chúng mình nên thống nhất điều gì để bớt hiểu lầm nhau?',
    'en': 'What should the two of you agree on to avoid misunderstandings?',
  },
  {
    'vi': 'Bạn hay thể hiện tình cảm bằng lời, hành động hay bằng quà?',
    'en': 'Do you show love more through words, actions, or gifts?',
  },
  {
    'vi': 'Có điều gì bạn ngại nói vì sợ người ấy buồn không?',
    'en': 'Is there something you hold back for fear of upsetting your partner?',
  },
  {
    'vi': 'Mỗi ngày chúng mình nên dành bao lâu chỉ để trò chuyện?',
    'en': 'How long each day should the two of you spend just talking?',
  },
  {
    'vi': 'Khi có tin vui, bạn muốn được ăn mừng theo cách nào?',
    'en': 'When something good happens, how do you like to celebrate?',
  },

  // ── Nhìn lại & trưởng thành (looking back & growing) — 12 ──────────────────
  {
    'vi': 'Ba năm trước bạn là người thế nào, giờ đã khác đi ra sao?',
    'en': 'Who were you three years ago, and how are you different now?',
  },
  {
    'vi': 'Quyết định nào từng rất khó mà giờ bạn thấy là đúng?',
    'en': 'Which decision felt hard once but seems right now?',
  },
  {
    'vi': 'Bạn từng tin điều gì về tình yêu mà nay đã nghĩ khác?',
    'en': 'What did you once believe about love that you now see differently?',
  },
  {
    'vi': 'Sai lầm nào đã dạy bạn nhiều nhất?',
    'en': 'Which mistake taught you the most?',
  },
  {
    'vi': 'So với trước, bạn thấy mình kiên nhẫn hơn ở chuyện gì?',
    'en': 'In what way are you more patient than you used to be?',
  },
  {
    'vi': 'Có điều gì bạn từng theo đuổi mà giờ thấy không cần nữa?',
    'en': 'Is there something you once chased that no longer matters?',
  },
  {
    'vi': 'Bạn muốn nói lời khuyên nào với chính mình năm mười tám tuổi?',
    'en': 'What advice would you give your eighteen-year-old self?',
  },
  {
    'vi': 'Năm nay bạn tự hào nhất về thay đổi nào của bản thân?',
    'en': 'Which change in yourself this year are you proudest of?',
  },
  {
    'vi': 'Điều gì từng làm bạn tổn thương mà giờ đã nhẹ đi nhiều?',
    'en': 'What once hurt you that feels much lighter now?',
  },
  {
    'vi': 'Sau những gì đã qua, bạn thấy mình mạnh mẽ hơn ở đâu?',
    'en': 'After all you have been through, where do you feel stronger?',
  },
  {
    'vi': 'Nếu gặp lại phiên bản mình của ngày xưa, bạn sẽ nói gì?',
    'en': 'If you met your past self, what would you say to them?',
  },
  {
    'vi': 'Bạn mong năm nay dạy mình bài học gì?',
    'en': 'What lesson do you hope this year teaches you?',
  },

  // ── Sáng tạo & giả tưởng (creative & imaginative) — 10 ─────────────────────
  {
    'vi': 'Nếu chúng mình có một bảo tàng tí hon, sẽ trưng bày những gì?',
    'en': 'If you two had a tiny museum, what would it display?',
  },
  {
    'vi': 'Bạn muốn viết một bài hát về phần nào trong chuyện của chúng mình?',
    'en': 'Which part of your story would you write a song about?',
  },
  {
    'vi': 'Nếu tình yêu của chúng mình là một màu, đó sẽ là màu gì?',
    'en': 'If your love were a color, which one would it be?',
  },
  {
    'vi': 'Nếu vẽ bản đồ chuyện tình chúng mình, trên đó có những nơi nào?',
    'en': 'If you mapped your love story, what places would be on it?',
  },
  {
    'vi': 'Bạn muốn thiết kế một căn phòng chỉ dành cho hai người ra sao?',
    'en': 'How would you design a room meant only for the two of you?',
  },
  {
    'vi': 'Nếu chúng mình làm một phim ngắn, cảnh cuối sẽ là cảnh gì?',
    'en': 'If you made a short film, what would the final scene be?',
  },
  {
    'vi': 'Nếu tình yêu của chúng mình là một mùa, đó là mùa nào?',
    'en': 'If your love were a season, which one would it be?',
  },
  {
    'vi': 'Bạn muốn đặt tên cho ngôi nhà tương lai của chúng mình là gì?',
    'en': 'What would you name your future home together?',
  },
  {
    'vi': 'Nếu làm một tấm bưu thiếp cho chúng mình, mặt trước vẽ gì?',
    'en': 'If you made a postcard for the two of you, what would the front show?',
  },
  {
    'vi': 'Nếu chúng mình có một câu khẩu hiệu riêng, đó sẽ là câu gì?',
    'en': 'If you two had your own motto, what would it be?',
  },

  // ── Lời hứa & mong muốn nhỏ (small promises & wishes) — 5 ──────────────────
  {
    'vi': 'Tuần này có điều nhỏ nào bạn muốn nhờ người ấy làm cho mình?',
    'en': 'Is there a small thing you would like your partner to do for you this week?',
  },
  {
    'vi': 'Tháng tới chúng mình nên hứa với nhau điều gì?',
    'en': 'What should the two of you promise each other for next month?',
  },
  {
    'vi': 'Tuần này bạn muốn rủ người ấy đi hẹn hò kiểu gì?',
    'en': 'What kind of date would you ask your partner for this week?',
  },
  {
    'vi': 'Có điều gì bạn mong người ấy đừng bao giờ ngừng làm không?',
    'en': 'Is there something you hope your partner never stops doing?',
  },
  {
    'vi': 'Bạn muốn tự hứa với mình điều gì để yêu thương tốt hơn?',
    'en': 'What would you promise yourself in order to love a little better?',
  },
];
