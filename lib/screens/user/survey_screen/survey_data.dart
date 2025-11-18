// Constant survey data derived from lib/data/qna.txt
// Format: single-choice per question with option ids and labels
const List<Map<String, dynamic>> kSurveyQuestionsData = [
  {
    'id': 'q_age',
    'text': 'Bạn thuộc nhóm độ tuổi nào?',
    'type': 'singleChoice',
    'displayOrder': 1,
    'options': [
      {'id': 'under_18', 'label': 'Dưới 18 tuổi'},
      {'id': '18_24', 'label': '18 – 24 tuổi'},
      {'id': '25_34', 'label': '25 – 34 tuổi'},
      {'id': '35_44', 'label': '35 – 44 tuổi'},
      {'id': '45_54', 'label': '45 – 54 tuổi'},
      {'id': '55_plus', 'label': '55 tuổi trở lên'},
    ],
  },
  {
    'id': 'q_purpose',
    'text': 'Bạn chủ yếu sử dụng máy tính cho mục đích gì?',
    'type': 'multiChoice',
    'displayOrder': 2,
    'options': [
      {'id': 'office', 'label': 'Học tập / Làm việc văn phòng'},
      {'id': 'design', 'label': 'Thiết kế đồ họa / Kiến trúc / Multimedia'},
      {'id': 'programming', 'label': 'Lập trình / Kỹ thuật'},
      {'id': 'gaming', 'label': 'Chơi game'},
      {
        'id': 'entertainment',
        'label': 'Giải trí đơn thuần (xem phim, nghe nhạc, lướt web)'
      },
    ],
  },
  {
    'id': 'q_current_device',
    'text': 'Bạn hiện đang sử dụng loại thiết bị nào là chính?',
    'type': 'singleChoice',
    'displayOrder': 3,
    'options': [
      {'id': 'laptop', 'label': 'Laptop'},
      {'id': 'prebuilt_pc', 'label': 'Máy bàn lắp ráp sẵn (pre-built PC)'},
      {'id': 'custom_pc', 'label': 'Máy bàn tự build từ linh kiện'},
    ],
  },
  {
    'id': 'q_preference',
    'text': 'Khi cần mua máy tính mới, bạn ưu tiên lựa chọn:',
    'type': 'singleChoice',
    'displayOrder': 4,
    'options': [
      {'id': 'prefer_laptop', 'label': 'Laptop'},
      {'id': 'prefer_prebuilt', 'label': 'PC lắp ráp sẵn (pre-built)'},
      {'id': 'prefer_custom', 'label': 'PC tự build từ linh kiện'},
      {'id': 'prefer_consult', 'label': 'Chưa rõ / Cần tư vấn'},
    ],
  },
  {
    'id': 'q_knowledge',
    'text': 'Mức độ am hiểu của bạn về phần cứng máy tính?',
    'type': 'singleChoice',
    'displayOrder': 5,
    'options': [
      {'id': 'novice', 'label': 'Không rành, chỉ nghe tư vấn'},
      {
        'id': 'basic',
        'label': 'Biết cơ bản (hiểu tên linh kiện, nhưng không chuyên sâu)'
      },
      {'id': 'advanced', 'label': 'Am hiểu khá (có thể tự chọn cấu hình)'},
      {'id': 'expert', 'label': 'Chuyên sâu (có thể tự build và tối ưu)'},
    ],
  },
  {
    'id': 'q_budget',
    'text': 'Ngân sách bạn dự kiến cho lần mua máy sắp tới?',
    'type': 'singleChoice',
    'displayOrder': 6,
    'options': [
      {'id': 'under_10m', 'label': 'Dưới 10 triệu'},
      {'id': '10_20m', 'label': '10 – 20 triệu'},
      {'id': '20_30m', 'label': '20 – 30 triệu'},
      {'id': '30_50m', 'label': '30 – 50 triệu'},
      {'id': 'over_50m', 'label': 'Trên 50 triệu'},
    ],
  },
  {
    'id': 'q_decision_factor',
    'text': 'Yếu tố quan trọng nhất khi quyết định mua máy?',
    'type': 'multiChoice',
    'displayOrder': 7,
    'options': [
      {'id': 'performance', 'label': 'Hiệu năng (cấu hình)'},
      {'id': 'price', 'label': 'Giá cả'},
      {'id': 'brand', 'label': 'Thương hiệu'},
      {'id': 'design', 'label': 'Thiết kế ngoại hình'},
      {'id': 'warranty', 'label': 'Bảo hành / Dịch vụ'},
      {'id': 'other', 'label': 'Khác'},
    ],
  },
  {
    'id': 'q_purchase_method',
    'text': 'Bạn thường quyết định mua máy theo cách nào?',
    'type': 'singleChoice',
    'displayOrder': 8,
    'options': [
      {'id': 'online_self', 'label': 'Mua online sau khi tự nghiên cứu'},
      {
        'id': 'online_influencer',
        'label': 'Mua online theo gợi ý từ reviewer/influencer'
      },
      {'id': 'offline_store', 'label': 'Mua offline tại cửa hàng'},
      {'id': 'friends_advice', 'label': 'Nghe tư vấn từ bạn bè/người thân'},
    ],
  },
];
