enum UserRole {
  marketer,
  creativeReviewer,
  complianceReviewer,
  financeApprover,
  administrator,
}

class MockPersona {
  final String id;
  final String name;
  final String title;
  final UserRole role;
  final int? authorizedStage; // 1 for Creative, 2 for Compliance, 3 for Finance

  const MockPersona({
    required this.id,
    required this.name,
    required this.title,
    required this.role,
    this.authorizedStage,
  });

  static const List<MockPersona> all = [
    MockPersona(
      id: 'usr_marketer_alex',
      name: 'Alex Chen',
      title: 'Campaign Manager (Creator)',
      role: UserRole.marketer,
    ),
    MockPersona(
      id: 'usr_creative_elena',
      name: 'Elena Rostova',
      title: 'Creative Director (Stage 1)',
      role: UserRole.creativeReviewer,
      authorizedStage: 1,
    ),
    MockPersona(
      id: 'usr_compliance_marcus',
      name: 'Marcus Vance',
      title: 'Legal Counsel (Stage 2)',
      role: UserRole.complianceReviewer,
      authorizedStage: 2,
    ),
    MockPersona(
      id: 'usr_finance_sophia',
      name: 'Sophia Sterling',
      title: 'Finance Director (Stage 3)',
      role: UserRole.financeApprover,
      authorizedStage: 3,
    ),
    MockPersona(
      id: 'usr_admin_david',
      name: 'David Ross',
      title: 'System Administrator',
      role: UserRole.administrator,
    ),
  ];

  static MockPersona get defaultPersona => all.first; // Alex (Marketer)
}

