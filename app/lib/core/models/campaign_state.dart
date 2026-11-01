enum CampaignState {
  draft,
  pendingReview,
  changesRequested,
  approved,
  scheduled,
  rejected;

  String get displayName {
    switch (this) {
      case CampaignState.draft:
        return 'Draft';
      case CampaignState.pendingReview:
        return 'Pending Review';
      case CampaignState.changesRequested:
        return 'Changes Requested';
      case CampaignState.approved:
        return 'Approved';
      case CampaignState.scheduled:
        return 'Scheduled';
      case CampaignState.rejected:
        return 'Rejected';
    }
  }

  String get code {
    switch (this) {
      case CampaignState.draft:
        return 'DRAFT';
      case CampaignState.pendingReview:
        return 'PENDING_REVIEW';
      case CampaignState.changesRequested:
        return 'CHANGES_REQUESTED';
      case CampaignState.approved:
        return 'APPROVED';
      case CampaignState.scheduled:
        return 'SCHEDULED';
      case CampaignState.rejected:
        return 'REJECTED';
    }
  }

  static CampaignState fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'DRAFT':
        return CampaignState.draft;
      case 'PENDING_REVIEW':
        return CampaignState.pendingReview;
      case 'CHANGES_REQUESTED':
        return CampaignState.changesRequested;
      case 'APPROVED':
        return CampaignState.approved;
      case 'SCHEDULED':
        return CampaignState.scheduled;
      case 'REJECTED':
        return CampaignState.rejected;
      default:
        return CampaignState.draft;
    }
  }
}

