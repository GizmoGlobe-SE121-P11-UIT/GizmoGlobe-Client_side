import 'package:gizmoglobe_client/generated/l10n.dart';

// Dynamic survey data using localization
// Returns questions and options translated based on current locale
List<Map<String, dynamic>> getSurveyQuestionsData(S s) => [
      {
        'id': 'q_age',
        'text': s.surveyQAge,
        'type': 'singleChoice',
        'displayOrder': 1,
        'options': [
          {'id': 'under_18', 'label': s.surveyOptUnder18},
          {'id': '18_24', 'label': s.surveyOpt18_24},
          {'id': '25_34', 'label': s.surveyOpt25_34},
          {'id': '35_44', 'label': s.surveyOpt35_44},
          {'id': '45_54', 'label': s.surveyOpt45_54},
          {'id': '55_plus', 'label': s.surveyOpt55Plus},
        ],
      },
      {
        'id': 'q_purpose',
        'text': s.surveyQPurpose,
        'type': 'multiChoice',
        'displayOrder': 2,
        'options': [
          {'id': 'office', 'label': s.surveyOptOffice},
          {'id': 'design', 'label': s.surveyOptDesign},
          {'id': 'programming', 'label': s.surveyOptProgramming},
          {'id': 'gaming', 'label': s.surveyOptGaming},
          {'id': 'entertainment', 'label': s.surveyOptEntertainment},
        ],
      },
      {
        'id': 'q_current_device',
        'text': s.surveyQCurrentDevice,
        'type': 'singleChoice',
        'displayOrder': 3,
        'options': [
          {'id': 'laptop', 'label': s.surveyOptLaptop},
          {'id': 'prebuilt_pc', 'label': s.surveyOptPrebuiltPc},
          {'id': 'custom_pc', 'label': s.surveyOptCustomPc},
        ],
      },
      {
        'id': 'q_preference',
        'text': s.surveyQPreference,
        'type': 'singleChoice',
        'displayOrder': 4,
        'options': [
          {'id': 'prefer_laptop', 'label': s.surveyOptPreferLaptop},
          {'id': 'prefer_prebuilt', 'label': s.surveyOptPreferPrebuilt},
          {'id': 'prefer_custom', 'label': s.surveyOptPreferCustom},
          {'id': 'prefer_consult', 'label': s.surveyOptPreferConsult},
        ],
      },
      {
        'id': 'q_knowledge',
        'text': s.surveyQKnowledge,
        'type': 'singleChoice',
        'displayOrder': 5,
        'options': [
          {'id': 'novice', 'label': s.surveyOptNovice},
          {'id': 'basic', 'label': s.surveyOptBasic},
          {'id': 'advanced', 'label': s.surveyOptAdvanced},
          {'id': 'expert', 'label': s.surveyOptExpert},
        ],
      },
      {
        'id': 'q_budget',
        'text': s.surveyQBudget,
        'type': 'singleChoice',
        'displayOrder': 6,
        'options': [
          {'id': 'under_10m', 'label': s.surveyOptUnder10m},
          {'id': '10_20m', 'label': s.surveyOpt10_20m},
          {'id': '20_30m', 'label': s.surveyOpt20_30m},
          {'id': '30_50m', 'label': s.surveyOpt30_50m},
          {'id': 'over_50m', 'label': s.surveyOptOver50m},
        ],
      },
      {
        'id': 'q_decision_factor',
        'text': s.surveyQDecisionFactor,
        'type': 'multiChoice',
        'displayOrder': 7,
        'options': [
          {'id': 'performance', 'label': s.surveyOptPerformance},
          {'id': 'price', 'label': s.surveyOptPrice},
          {'id': 'brand', 'label': s.surveyOptBrand},
          {'id': 'design', 'label': s.surveyOptDesignLook},
          {'id': 'warranty', 'label': s.surveyOptWarranty},
          {'id': 'other', 'label': s.surveyOptOther},
        ],
      },
      {
        'id': 'q_purchase_method',
        'text': s.surveyQPurchaseMethod,
        'type': 'singleChoice',
        'displayOrder': 8,
        'options': [
          {'id': 'online_self', 'label': s.surveyOptOnlineSelf},
          {'id': 'online_influencer', 'label': s.surveyOptOnlineInfluencer},
          {'id': 'offline_store', 'label': s.surveyOptOfflineStore},
          {'id': 'friends_advice', 'label': s.surveyOptFriendsAdvice},
        ],
      },
    ];
