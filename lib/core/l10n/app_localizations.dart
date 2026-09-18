/// Centralised bilingual string map for IbuDaya.
///
/// Access: `AppLocalizations.of(context).someKey`
///
/// Both [_IdStrings] and [_EnStrings] must define every key. A compile-time
/// error is thrown if either map is incomplete (abstract class enforcement).
///
/// IMPLEMENTATION STATUS: IMPLEMENTED — two concrete subclasses keyed to
/// Locale('id') and Locale('en').
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_provider.dart';

// ---------------------------------------------------------------------------
// InheritedWidget wrapper — screens call AppLocalizations.of(context)
// ---------------------------------------------------------------------------

class AppLocalizationsScope extends InheritedWidget {
  const AppLocalizationsScope({
    super.key,
    required this.l10n,
    required super.child,
  });

  final AppLocalizations l10n;

  @override
  bool updateShouldNotify(AppLocalizationsScope old) => l10n != old.l10n;
}

/// Widget that watches the [localeProvider] and places an [AppLocalizationsScope]
/// above its child — call once in [IbuDayaApp].
class AppLocalizationsProvider extends ConsumerWidget {
  const AppLocalizationsProvider({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(resolvedLocaleProvider);
    final l10n = AppLocalizations.forLocale(locale);
    return AppLocalizationsScope(l10n: l10n, child: child);
  }
}

// ---------------------------------------------------------------------------
// Abstract base — every key is a getter; subclasses must implement all of them
// ---------------------------------------------------------------------------

abstract class AppLocalizations {
  const AppLocalizations();

  factory AppLocalizations.forLocale(Locale locale) {
    if (locale.languageCode == 'en') return const _EnStrings();
    return const _IdStrings(); // id is the default
  }

  /// Retrieves [AppLocalizations] from the nearest [AppLocalizationsScope]
  /// ancestor in the widget tree.
  static AppLocalizations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLocalizationsScope>();
    assert(scope != null, 'AppLocalizationsScope not found in widget tree');
    return scope!.l10n;
  }

  /// Whether the current localization is English.
  bool get isEn => this is _EnStrings;

  // ── App ──────────────────────────────────────────────────────────────────
  String get appName;
  String get appTagline;

  // ── Bottom Navigation ────────────────────────────────────────────────────
  String get navHome;
  String get navRecords;
  String get navSolarHub;
  String get navMessages;
  String get navProfile;
  String get navDashboard;
  String get navSubmissions;
  String get navMembers;
  String get navOther;

  // ── Common actions ───────────────────────────────────────────────────────
  String get actionSave;
  String get actionCancel;
  String get actionContinue;
  String get actionBack;
  String get actionClose;
  String get actionConfirm;
  String get actionDelete;
  String get actionEdit;
  String get actionAdd;
  String get actionSubmit;
  String get actionRefresh;
  String get actionViewAll;
  String get actionViewDetail;
  String get actionReadAll;
  String get actionLogout;
  String get actionLogin;
  String get actionRegister;
  String get actionNext;
  String get actionSend;
  String get actionApply;
  String get actionUploadGallery;

  // ── Common labels ────────────────────────────────────────────────────────
  String get labelLoading;
  String get labelError;
  String get labelSuccess;
  String get labelRequired;
  String get labelOptional;
  String get errorGenericRetry;
  String unitMonths(int n);
  String get roofOrientationNorth;
  String get roofOrientationEastWest;
  String get roofOrientationSouth;
  String get roofOrientationFlat;
  String get roofOrientationUnknown;
  String get roofShadingNone;
  String get roofShadingPartial;
  String get roofShadingHeavy;
  String get roofBandVeryFeasible;
  String get roofBandFeasible;
  String get roofBandFairlyFeasible;
  String get roofBandLessFeasible;
  String get roofScanSkipPhoto;
  String get roofSavingPhotoLabel;
  String get roofSizeTitle;
  String get roofCalculateAction;
  String get roofMeasureHint;
  String get roofLengthLabel;
  String get roofWidthLabel;
  String roofFieldRequired(String label);
  String get roofFieldTooLarge;
  String roofAreaSummary(String total, String usable);
  String get roofOrientationQuestion;
  String get roofShadingQuestion;
  String get roofResultTitle;
  String get roofSavedLabel;
  String get roofSaveAction;
  String get roofSavedToast;
  String get roofPotentialLabel;
  String get roofProductionSection;
  String get roofUsableArea;
  String get roofMonthlyEnergy;
  String get roofYourLastUsage;
  String get roofSavingsSection;
  String get roofSavingsPerMonth;
  String get roofSavingsPerYear;
  String get roofCostSection;
  String get roofInstallCost;
  String get roofPayback;
  String roofPaybackYears(String years);
  String get threadNotFound;
  String get threadMessageHint;
  String get energyKindToken;
  String get energyKindBill;
  String get roofAssumptionsTitle;
  String roofAssumptionsBody(
    String usableFraction,
    String sqmPerKwp,
    String sunHours,
    String performanceRatio,
    String siteFactor,
    String costPerKwp,
    String tariff,
  );
  String get labelStatus;
  String get labelDate;
  String get labelAmount;
  String get labelNote;
  String get labelPhone;
  String get labelName;
  String get labelCity;
  String get labelBusinessName;
  String get labelPin;
  String get labelNewPin;
  String get labelConfirmPin;
  String get labelInviteCode;
  String get labelSearch;
  String get labelFilter;
  String get labelTotal;
  String get labelApproved;
  String get labelRejected;
  String get labelPending;
  String get labelCompleted;
  String get labelActive;
  String get labelEstimation;
  String get labelSince;

  // ── Welcome / Auth ───────────────────────────────────────────────────────
  String get welcomeHeadline;
  String get welcomeFeatureSolar;
  String get welcomeFeatureArisan;
  String get welcomeTrySample;
  String get welcomeSampleTitle;
  String get welcomeSampleBanner;
  String get welcomeLoginAs;

  String get loginTitle;
  String get loginPhonePrompt;
  String get loginPhoneHint;
  String get loginPhoneLabel;
  String get loginPhoneHelper;
  String get loginPhoneError;
  String get loginNoAccount;
  String get loginPinTitle;
  String get loginPinSubtitle;
  String get loginForgotPin;
  String get loginForgotPinTitle;
  String get loginForgotPinBody;
  String get loginClearData;
  String get loginClearDataConfirmTitle;
  String get loginClearDataConfirmBody;
  String get loginClearDataConfirmLabel;
  String get loginClearDataSuccess;
  String get loginUnderstood;

  String get registerTitle;
  String get registerPrompt;
  String get registerSubtitle;
  String get registerAsMember;
  String get registerMemberBody;
  String get registerMemberCta;
  String get registerAsAdmin;
  String get registerAdminBody;
  String get registerAdminCta;
  String get registerHaveAccount;

  String get registerMemberTitle;
  String get registerMemberStep0Title;
  String get registerMemberStep0Subtitle;
  String get registerMemberCodeHint;
  String get registerMemberCodeError;
  String get registerMemberJoiningTo;
  String get registerMemberFieldName;
  String get registerMemberFieldNameHint;
  String get registerMemberFieldBusiness;
  String get registerMemberFieldBusinessHint;
  String get registerMemberFieldCity;
  String get registerMemberFieldPhone;
  String get registerMemberFieldPhoneHelper;
  String get registerMemberFieldPhoneError;
  String get registerMemberSuccess;
  String registerMemberSuccessNamed(String coopName);
  String get registerMemberGenericCoop;

  String get registerAdminTitle;
  String get registerAdminCoopName;
  String get registerAdminCoopNameHint;
  String get registerAdminCoopCity;
  String get registerAdminPinCreated;
  String get registerStepPerson;
  String get registerStepCoop;
  String get registerStepCode;
  String get registerAdminSectionPerson;
  String get registerAdminCoopHeading;
  String get registerAdminAfterTitle;
  String get registerAdminAfterBody;
  String get registerAdminLegalWarning;
  String fieldRequired(String label);

  String get sampleTitle;
  String get sampleMessage;
  String get sampleConfirmLabel;

  // ── Scaffold / AppBar ────────────────────────────────────────────────────
  String get scaffoldProfile;
  String get scaffoldNotifications;
  String get scaffoldEnergy;
  String get scaffoldEnergyAdd;
  String get scaffoldEnergyAnalysis;
  String get scaffoldAppliances;
  String get scaffoldApplianceEdit;
  String get scaffoldRoof;
  String get scaffoldBooking;
  String get scaffoldBookings;
  String get scaffoldArisan;
  String get scaffoldQuota;
  String get scaffoldQuotaNew;
  String get scaffoldScore;
  String get scaffoldLoans;
  String get scaffoldLoanDetail;
  String get scaffoldLoanApply;
  String get scaffoldMessages;
  String get scaffoldThread;
  String get scaffoldProfileEdit;
  String get scaffoldChangePin;
  String get scaffoldAbout;
  String get scaffoldLanguage;
  String get scaffoldAdminDashboard;
  String get scaffoldAdminLoans;
  String get scaffoldAdminMembers;
  String get scaffoldAdminOther;
  String get scaffoldAdminPayments;
  String get scaffoldAdminArisan;
  String get scaffoldAdminHub;
  String get scaffoldAdminAnnounce;
  String get scaffoldAdminSettings;

  // ── Home ─────────────────────────────────────────────────────────────────
  String greetingName(String name);
  String get homeHelloPrefix;
  String get homeBillLabel;
  String billMonthLabel(String month);
  String get homeBillNoData;
  String get homeBillNoDataHint;
  String get homeChangePctSuffix;
  String get homeAnalysis;
  String get homeStatusHeader;
  String get homeBookingHub;
  String get homeArisanEnergi;
  String get homeTukarKuota;
  String get homeSkorKredit;
  String get homePembiayaan;
  String get homeCatatanListrik;
  String get homeAlatUsaha;
  String get homeScoreNotReady;
  String homeScoreMonthsNeeded(int n);
  String get homeScoreTitle;
  String homeLoanCanApply(String amount);
  String homeLoanInstallment(int seq, String amount, String date);
  String get homeLoanOverdue;
  String get homeLoanDue;
  String get homeImpactTitle;
  String get homeImpactThisMonth;
  String get homeImpactSolarEnergy;
  String get homeImpactCo2;
  String get homeImpactCo2Note;
  String homeFromTokens(int count);

  // ── Profile ───────────────────────────────────────────────────────────────
  String get profileTitle;
  String get profileMonthsRecorded;
  String get profileSinceJoined;
  String get profileHubSessions;
  String get profileHubActivities;
  String get profileEnergyCredit;
  String get profileCategory;
  String get profileSectionBusiness;
  String get profileMenuEnergy;
  String get profileMenuAppliances;
  String get profileMenuSolarSchedule;
  String get profileMenuScore;
  String get profileMenuLoans;
  String get profileSectionAccount;
  String get profileMenuEditProfile;
  String get profileMenuChangePin;
  String get profileMenuNotifications;
  String get profileMenuAbout;
  String get profileMenuLanguage;
  String get profileLogout;
  String get profileLogoutTitle;
  String get profileLogoutMessage;
  String get profileLogoutConfirm;

  // ── Language Screen ───────────────────────────────────────────────────────
  String get languageTitle;
  String get languageSubtitle;
  String get languageId;
  String get languageEn;

  // ── Energy ────────────────────────────────────────────────────────────────
  String get energyTitle;
  String get energyEmpty;
  String get energyEmptyMessage;
  String get energyAutoNote;
  String get energyMonth;
  String get energyKwh;
  String get energyBill;
  String get energyTariff;
  String get energySourceHub;
  String get energySourceManual;
  String get energySaveSuccess;
  String get energyAnalysisTitle;
  String get energyAnalysisEmpty;
  String get energyAnalysisNoAppliances;
  String get energyAnalysisTrend;
  String get energyAnalysisContributors;

  // Manual "Catat Listrik" form fields (kind-specific copy)

  // Scan result / analysis screen (shared by the scan result and Analisis
  // Energi screens so a translation never drifts between the two)
  String get scanAnalysisSubtitle;
  String get scanAnalysisHelpOk;
  String get scanAnalysisHelpTooltip;
  String get scanAnalysisAppliancesSectionTitle;
  String get scanAnalysisPerMonthSuffix;
  String get scanAnalysisInsightTitle;
  String get scanAnalysisEmptyMessage;
  String get scanAnalysisCtaSolarHub;
  String get energyAnalysisUseSolarHub;
  String get scanAnalysisLoadingSubtitle;
  String get scanAnalysisLoadingBadge;
  String get scanStep1;
  String get scanStep2;
  String get scanStep3;
  String get scanStep4;
  String get scanStep5;

  // ── Appliances ────────────────────────────────────────────────────────────
  String get appliancesTitle;
  String get appliancesEmpty;
  String get appliancesEmptyMessage;
  String get appliancesAdd;
  String get applianceFormTitle;
  String get applianceFormName;
  String get applianceFormWatt;
  String get applianceFormHoursPerDay;
  String get applianceFormDaysPerWeek;
  String get applianceFormCategory;
  String get applianceSaveSuccess;
  String get applianceDeleteConfirmTitle;
  String get scaffoldApplianceAdd;
  String get applianceDeleteConfirmMessage;
  String get applianceDeletedToast;
  String get applianceFormNameRequired;
  String get applianceFormWattRequired;
  String get applianceFormWattTooLarge;
  String get applianceFormWattHelper;
  String get applianceMonthlyLabel;
  String get applianceMonthlyCostLabel;
  String applianceHoursValue(String hours);

  // Shared camera capture chrome (used by Radar Atap and the hub-connect
  // QR scanner)
  String get captureTorchOn;
  String get captureTorchOff;
  String get captureCameraNotFound;
  String get captureCameraDenied;
  String get captureCameraUnavailable;
  String get captureShootFailed;
  String get captureGalleryFailed;
  String get captureGalleryLabel;
  String get captureShootSemanticLabel;
  String get captureDefaultBusyLabel;

  // ── Solar Hub ─────────────────────────────────────────────────────────────
  String get solarTitle;
  String get solarNoHub;
  String get solarNoHubMessage;
  String get solarCapacity;
  String get solarBook;
  String get solarMyBookings;
  String get solarSlotAvailable;
  String get solarSlotFull;
  String get solarBookingTitle;
  String get solarBookingAppliance;
  String get solarBookingDate;
  String get solarBookingSlot;
  String get solarBookingConfirm;
  String get solarBookingSuccess;
  String get solarBookingsTitle;
  String get solarBookingsEmpty;
  String get solarRoofTitle;
  String get solarRoofHint;
  String get solarRoofTip1;
  String get solarRoofTip2;
  String get solarRoofCapture;
  String get solarRoofAnalysing;
  String get solarRoofResult;

  // ── Arisan ────────────────────────────────────────────────────────────────
  String get arisanTitle;
  String get arisanNoGroup;
  String get arisanNoGroupMessage;
  String get arisanGroupName;
  String get arisanCycle;
  String get arisanDues;
  String get arisanPay;
  String get arisanHistory;
  String get arisanQuota;
  String get arisanQuotaTitle;
  String get arisanQuotaEmpty;
  String get arisanQuotaNew;
  String get arisanQuotaNeed;
  String get arisanQuotaShare;
  String get arisanQuotaAmount;

  // ── Credit Score ──────────────────────────────────────────────────────────
  String get scoreFactors;
  String get scoreAbout;
  String get scoreAboutBody;
  String get scoreApply;
  String get scoreViewLoans;
  String get scoreCanApply;
  String scoreCanApplyAmount(String amount);
  String get scoreDecision;
  String scoreWithBand(int score, String band);
  String get scoreShortLabel;
  String get scoreHistoryTitle;
  String scoreUpdatedAt(String when);

  // ── Loans ─────────────────────────────────────────────────────────────────
  String get loansTitle;
  String get loansEmpty;
  String get loansEmptyMessage;
  String get loansApply;
  String get loanApplyTitle;
  String get loanApplyAmount;
  String get loanApplyTenor;
  String get loanApplyPurpose;
  String get loanApplyConfirm;
  String get loanApplySuccess;
  String get loanDetailTitle;
  String get loanStatus;
  String get loanAmount;
  String get loanInstallments;
  String get loanApprovedBy;
  String get loanDisbursedOn;
  String get loanToastInReview;
  String get loanToastApproved;
  String get loanToastDisbursed;
  String get loanToastCancelled;
  String get loanToastRejected;
  String get loanToastInstallmentRecorded;
  String get paymentToastRejected;
  String get paymentToastConfirmed;

  // ── Messages ──────────────────────────────────────────────────────────────
  String get messagesTitle;
  String get messagesEmpty;
  String get messagesEmptyMessage;
  String get threadTitle;
  String get threadReply;
  String get threadSend;

  // ── Notifications ─────────────────────────────────────────────────────────
  String get notificationsTitle;
  String get notificationsEmpty;
  String get notificationsEmptyMessage;
  String get notificationsReadAll;

  // ── Edit Profile ──────────────────────────────────────────────────────────
  String get editProfileTitle;
  String get editProfileName;
  String get editProfileBusiness;
  String get editProfileCity;
  String get editProfileTariff;
  String get editProfileSave;
  String get editProfileSuccess;

  // ── Change PIN ────────────────────────────────────────────────────────────
  String get changePinTitle;
  String get changePinCurrentPin;
  String get changePinNewPin;
  String get changePinSuccess;

  // ── About ─────────────────────────────────────────────────────────────────
  String get aboutTitle;
  String get aboutVersion;
  String get aboutClearSample;
  String get aboutClearSampleConfirmTitle;
  String get aboutClearSampleConfirmBody;
  String get aboutClearSampleSuccess;
  String get aboutResetDevice;
  String get aboutResetDeviceConfirmTitle;
  String get aboutResetDeviceConfirmBody;
  String get aboutResetDeviceSuccess;
  String get aboutTagline;
  String get aboutDescription;
  String get aboutNumbersSection;
  String get aboutNumbersBody;
  String get aboutDataStorageSection;
  String get aboutDataStorageBody;
  String aboutFooter(String teamName);
  String get inviteCardFirstMember;
  String get inviteCardTitle;
  String get inviteCardCopyTooltip;
  String inviteCardShareMessage(String coopName, String code);
  String get inviteCardCopiedToast;
  String get inviteCardCaption;
  String arisanQuotaActionConfirmTitle(String action);
  String get arisanQuotaUpdatedToast;
  String get arisanQuotaSentToast;
  String get bookingCancelledToast;
  String get bookingRecordedToast;
  String solarBookingComeOnTime(String hubName);
  String get bookingCustomApplianceSublabel;
  String get appliancesMonthlyEstimateLabel;
  String loginPinForPhone(String phone);

  // ── Admin Dashboard ───────────────────────────────────────────────────────
  String get adminDashTitle;
  String get adminMembers;
  String get adminSectionManage;
  String get adminPaymentsMenu;
  String get adminArisanMenu;
  String get adminHubMenu;
  String get adminAnnounceMenu;
  String get adminMessagesMenu;
  String get adminSettingsMenu;
  String get adminSettingsSubtitle;
  String get adminSectionAccount;
  String get adminEditProfile;
  String get adminChangePin;

  String get adminLoansTitle;
  String get adminLoansEmpty;
  String get adminLoansEmptyMessage;

  String get adminMembersTitle;
  String get adminMembersEmpty;
  String get adminMembersEmptyMessage;
  String get adminMemberDetailTitle;
  String get adminMemberNotFound;
  String get adminMemberSendMessage;
  String get adminMemberElectricityLast3Months;
  String get adminMemberLoansSection;
  String get adminMemberNoLoans;
  String get adminMemberNoScore;
  String get adminMemberScorePendingShort;
  String get adminMemberArisanSection;

  String get adminPaymentsTitle;
  String get adminPaymentsEmpty;
  String get adminPaymentsApprove;
  String get adminPaymentsReject;

  String get adminArisanTitle;
  String get adminArisanNewGroup;
  String get adminArisanGroupName;
  String get adminArisanDues;
  String get adminArisanCycle;
  String get arisanAdminCreateGroupButton;
  String get arisanAdminEmptyTitle;
  String get arisanAdminEmptyMessage;
  String get arisanAdminDuesPerMonth;
  String arisanAdminMemberCount(int n);
  String get arisanAdminStartMonth;
  String get arisanAdminPaidThisMonth;
  String arisanAdminDisbursedTo(String name, String amount);
  String arisanAdminRecordPayoutTo(String name);
  String get arisanAdminRecordPayoutConfirmTitle;
  String arisanAdminRecordPayoutConfirmMessage(
    String amount,
    String name,
    String month,
  );
  String arisanAdminRecordPayoutWarning(int paid, int total);
  String get arisanAdminRecordPayoutAction;
  String get arisanAdminPayoutRecordedToast;
  String get arisanAdminTurnOrderSection;
  String get arisanAdminCreateTitle;
  String arisanAdminCreateButton(int n);
  String get arisanAdminGroupNameRequired;
  String get arisanAdminMinAmount;
  String get arisanAdminStartMonthLabel;
  String get arisanAdminPickMembersTitle;
  String get arisanAdminPickMembersHint;
  String get arisanAdminNeedMoreMembers;
  String get arisanAdminGroupCreatedToast;
  String get arisanDrawButton;
  String get arisanDrawDialogTitle;
  String get arisanDrawHint;
  String get arisanDrawInProgress;
  String arisanDrawSlot(int turn, String name);
  String get arisanDrawRedo;
  String get arisanDrawConfirm;
  String get arisanDrawCancel;

  String get adminHubTitle;
  String get adminHubCapacity;
  String get adminHubSlots;
  String get hubNotFound;
  String get hubFieldName;
  String get hubFieldNameRequired;
  String get hubFieldLocation;
  String get hubFieldCapacity;
  String get hubFieldCapacityHelper;
  String get hubFieldCapacityRequired;
  String get hubCapacityUnknownTitle;
  String get hubCapacityHint;
  String hubCapacitySuggestion(String kwh);
  String get hubCapacityUse;
  String get hubFieldWeatherCode;
  String get hubFieldWeatherCodeHelper;
  String get hubFieldQuota;
  String get hubFieldQuotaHelper;
  String get hubFieldQuotaRequired;
  String get hubSlotsSection;
  String get hubAddSlotDialogTitle;
  String get hubSlotStart;
  String get hubSlotEnd;
  String get hubSlotAddedToast;
  String get hubSlotDeleteTooltip;
  String hubSlotDeleteConfirmTitle(String label);
  String get hubSlotDeleteConfirmMessage;
  String get hubSlotDeletedToast;
  String hubSlotHours(int hours);
  String get hubBookingsToConfirmSection;
  String get hubBookingMarkUsed;
  String get hubBookingMarkedUsedToast;
  String get hubConnectionRequestsSection;
  String get hubConnectionApprove;
  String adminSummarySubtitle(int active, int total, int ready, int trades);
  String get adminSummaryActive;
  String get adminSummaryLoanReady;
  String get adminSummaryTrades;
  String get adminSummaryTradedKwh;
  String get adminSummaryUtilization;
  String get adminSummaryUtilizationHint;
  String get adminSummaryRepayment;
  String get adminSummaryRepaymentNone;
  String adminSummaryRepaymentDetail(int ok, int due);
  String get loanReadyBadge;
  String get adminKpiTitle;
  String get adminKpiNote;
  String get creditReportTitle;
  String get creditReportOpen;
  String get creditReportEmpty;
  String get creditReportIntro;
  String get creditReportCopy;
  String get creditReportConsentTitle;
  String get creditReportConsentBody;
  String get creditReportCopied;
  String get creditReportMonths;
  String get creditReportActivity;
  String creditReportSessions(int n, String kwh);
  String get creditReportAppliances;
  String get creditReportQuota;
  String creditReportQuotaValue(int given, int received);
  String get creditReportDues;
  String get creditReportInstallments;
  String creditReportInstallmentsValue(int ok, int due);
  String get creditReportInstallmentsNone;
  String get quotaShareToAny;
  String get quotaShareToMember;
  String get quotaShareToAnyHint;
  String get quotaShareToMemberHint;
  String get quotaPickMember;
  String get quotaPickMemberRequired;
  String get quotaGiftIncomingTitle;
  String quotaGiftFrom(String name, String kwh);
  String get quotaGiftAccept;
  String get quotaGiftDecline;
  String get quotaGiftAcceptedToast;
  String get quotaGiftDeclinedToast;
  String quotaGiftWaiting(String name);
  String quotaGiftSentMessage(String name);
  String get quotaMatchTitle;
  String get quotaMatchRule;
  String quotaMatchShareCovers(String kwh);
  String quotaMatchShareShort(String kwh, String missing);
  String quotaMatchNeedFits(String kwh);
  String get quotaTradedToast;
  String quotaTradeConfirm(String kwh, String name);
  String get quotaLedgerTitle;
  String quotaLedgerGave(String name);
  String quotaLedgerGot(String name);
  String get quotaLedgerEmpty;
  String get quotaLedgerNote;
  String get hubConnectSending;
  String get hubConnectScanAgain;
  String get hubConnectApprovedTitle;
  String get hubConnectApprovedMessage;
  String get hubConnectRejectedTitle;
  String get hubConnectRejectedMessage;
  String get hubConnectDoneTitle;
  String get hubConnectDoneMessage;
  String get hubConnectBrowse;
  String get adminRequestsTitle;
  String get adminRequestsEmpty;
  String get adminRequestsIntro;
  String get adminRequestsCardTitle;
  String get hubConnectionReject;
  String get hubConnectionApprovedToast;
  String get hubConnectionRejectedToast;

  // ── Hub connect (QR verification request) ──────────────────────────────
  String get hubConnectCta;
  String get hubConnectTitle;
  String get hubConnectInstruction;
  String get hubConnectWrongCode;
  String get hubConnectOffHours;
  String get hubConnectSentTitle;
  String get hubConnectSentMessage;

  // ── Admin: member hub capacity/connection ───────────────────────────────
  String get adminMemberHubSection;
  String get adminMemberHubAllocation;
  String get adminMemberHubAllocationHint;
  String get adminMemberHubAllocationHelper;

  String get adminAnnounceTitle;
  String get adminAnnounceMessage;
  String get adminAnnounceSend;
  String get adminAnnounceSent;
  String adminAnnounceSendCount(int count);
  String get adminAnnounceConfirmTitle;
  String get adminAnnounceConfirmMessage;
  String get adminAnnounceConfirmSend;
  String get adminAnnounceHint;
  String get adminAnnounceHelper;
  String get adminAnnouncePreviousSection;

  String get adminSettingsTitle;
  String get adminSettingsInviteCode;
  String get adminSettingsLoanCeiling;
  String get adminSettingsLoanMin;
  String get adminSettingsTenor;
  String get adminSettingsInterest;
  String get adminSettingsSave;
  String get adminSettingsSaved;
  String get coopSettingsNewCodeButton;
  String get coopSettingsNewCodeConfirmTitle;
  String coopSettingsNewCodeConfirmMessage(String oldCode);
  String get coopSettingsNewCodeToast;
  String get coopSettingsNameLabel;
  String get coopSettingsNameRequired;
  String get coopSettingsArisanSection;
  String get coopSettingsBankAccountLabel;
  String get coopSettingsBankAccountHelper;
  String get coopSettingsLoanPolicySection;
  String get coopSettingsLoanPolicyWarning;
  String get coopSettingsCeilingRequired;
  String coopSettingsCeilingByScore(String bands);
  String get coopSettingsInterestRequired;
  String get coopSettingsTenorRequiredToast;
  String get coopSettingsTenorSection;

  // ── Extra Localizations ──────────────────────────────────────────────────
  String monthShort(int month);
  String monthLong(int month);
  String dayShort(int weekday);
  String get dateYesterday;

  String get qualifierEstimasi;
  String get qualifierEstimasiAwal;
  String get qualifierSimulasi;
  String get qualifierIlustrasi;
  String get qualifierDataContoh;
  String get qualifierDataKomunitas;
  String get qualifierDataLangsung;

  String get solarWeatherTitle;
  String solarWeatherReason(int cloudPct, String condition);
  String get solarWeatherSource;
  String solarWeatherScore(int score, int tempC);
  String get solarWeatherRainNote;
  String get solarBookingBestWeather;
  String get solarWeatherPassedTitle;
  String get solarWeatherPassedHint;
  String get solarWeatherTomorrowTitle;

  // ── Solar panel QR scan (demo) ───────────────────────────────────────────

  String get creditBandPerluPeningkatan;
  String get creditBandCukup;
  String get creditBandBaik;
  String get creditBandBaikSekali;

  String get roleAdmin;
  String get roleMember;

  String get appliancePresetOven;
  String get appliancePresetKulkas;
  String get appliancePresetMesinJahit;
  String get appliancePresetBlender;
  String get appliancePresetRiceCooker;
  String get appliancePresetMixer;
  String get appliancePresetSetrika;
  String get appliancePresetKipasAngin;
  String get appliancePresetLainnya;

  String obsSpikeTitle(int pct);
  String obsSpikeBodyExtra(String extra);
  String get obsSpikeBodyAvg;
  String obsSavingTitle(int pct);
  String get obsSavingBody;
  String get obsMismatchTitle;
  String get obsMismatchBody;
  String obsTopApplianceTitle(String name);
  String obsTopApplianceBody(String cost);
  String get obsConfirmBookingTitle;
  String obsConfirmBookingBody(int count);
  String get obsUseHubTitle;
  String get obsUseHubBody;
  String get obsNoApplianceTitle;
  String get obsNoApplianceBody;

  String energyAnalysisUsage(String month);
  String get energyAnalysisNoPrev;
  String energyAnalysisUp(int pct, String month, String extra);
  String energyAnalysisDown(int pct, String month);
  String energyAnalysisMoreExpensive(String extra);
  String get energyAnalysisSpikeTitle;
  String get energyAnalysisSpikeBody;
  String get energyAnalysisTrend6Months;
  String get energyAnalysisBreakdownTitle;
  String energyAnalysisMismatchBody(String declared, String actual);
  String get energyAnalysisUnregistered;
  String get energyAnalysisSavingTipTitle;
  String energyAnalysisSavingTipBody(String name, String kwh, String cost);
  String energyAnalysisFormula(String tariff);

  String get solarHubCoop;
  String get solarCapacityToday;
  String solarCapacityAvailable(String rem, String cap);
  String get solarBookingScheduleBtn;
  String get solarQuotaThisMonth;
  String solarQuotaRemaining(String rem);
  String solarQuotaAllocationUsed(String alloc, String booked);
  String get solarSwap;
  String get solarTodaySlots;
  String get solarSlotCapacityNote;
  String get solarSlotPassed;
  String get solarMyScheduleAll;
  String get solarNoUpcoming;

  String get loanStatusSubmitted;
  String get loanStatusInReview;
  String get loanStatusApproved;
  String get loanStatusRejected;
  String get loanStatusDisbursed;
  String get loanStatusRepaid;
  String get loanStatusCancelled;
  String get loanPurposeRawMaterial;
  String get loanPurposeEquipment;
  String get loanPurposeRenovation;
  String get loanPurposeOther;

  String get paymentStatusPending;
  String get paymentStatusConfirmed;
  String get paymentStatusRejected;
  String get paymentTypeContribution;
  String get paymentTypePayout;
  String get bookingStatusPendingVerification;
  String get bookingStatusBooked;
  String get bookingStatusCompleted;
  String get bookingStatusCancelled;

  String get arisanNotJoinedTitle;
  String get arisanNotJoinedMsg;
  String get arisanSendMessageToAdmin;
  String get arisanGroupChat;
  String get arisanTotalPerMonth;
  String get arisanDuesLabel;
  String get arisanTurnThisMonth;
  String get arisanYourTurn;
  String arisanDuesMonth(String month);
  String arisanStartsMonth(String month);
  String get arisanPrevRejected;
  String get arisanPrevRejectedNote;
  String arisanPayInstruction(String amount);
  String arisanPayInstructionWithBank(String amount, String bankAccount);
  String get arisanPaidBtn;
  String get arisanPaidSuccess;
  String get arisanPaidPending;
  String arisanPayoutInfo(String name, String amount);
  String get arisanEnergyTrading;
  String get arisanEnergyTradingSub;
  String arisanMembersCount(int count);
  String get arisanMyHistory;
  String get arisanPayConfirmTitle;
  String arisanPayConfirmMsg(String amount);
  String get arisanYouTag;
  String arisanTurnFormat(int turn, String month);
  String get arisanReceivingThisMonth;
  String get arisanNotPaidYet;
  String get arisanPaidStatus;
  String get arisanWaitingStatus;

  String get scoreNotCalculatedTitle;
  String scoreNotCalculatedMsg(int min);
  String scoreRecordsCount(int current, int min);
  String get scoreRecordsEnough;
  String scoreUseHubMoreMonths(int n);
  String get scoreUseHubMoreMonthsSubtitle;
  String get scoreInArisan;
  String get scoreJoinArisan;
  String scoreAppliancesDeclaredCount(int count);
  String get scoreRegisterAppliance;
  String get scoreFrom100;
  String get scoreFirstThisMonth;
  String scoreSameAsMonth(String month);
  String scoreDeltaUpFromMonth(int pts, String month);
  String scoreDeltaDownFromMonth(int pts, String month);
  String loanCeilingTitle(String amount);
  String get loanCannotApply;
  String loanCeilingFromScore(int score, String band);
  String loanCoopPolicy(
    String coop,
    String max,
    String rate,
    String tenors,
    int minScore,
  );
  String get loanMySubmissions;
  String get loanNoSubmissions;

  String get eligibilityNone;
  String get eligibilityNotEnoughHistory;
  String get eligibilityScoreTooLow;
  String get eligibilityActiveLoan;
}

// ---------------------------------------------------------------------------
// Bahasa Indonesia (default)
// ---------------------------------------------------------------------------

class _IdStrings extends AppLocalizations {
  const _IdStrings();

  @override
  String get appName => 'IbuDaya';
  @override
  String get appTagline =>
      'Bantu usaha Anda tumbuh lebih efisien\ndengan solusi energi yang terjangkau';

  // Nav
  @override
  String get navHome => 'Beranda';
  @override
  String get navRecords => 'Catatan';
  @override
  String get navSolarHub => 'Solar Hub';
  @override
  String get navMessages => 'Pesan';
  @override
  String get navProfile => 'Profil';
  @override
  String get navDashboard => 'Dasbor';
  @override
  String get navSubmissions => 'Pengajuan';
  @override
  String get navMembers => 'Anggota';
  @override
  String get navOther => 'Lainnya';

  // Actions
  @override
  String get actionSave => 'Simpan';
  @override
  String get actionCancel => 'Batal';
  @override
  String get actionContinue => 'Lanjut';
  @override
  String get actionBack => 'Kembali';
  @override
  String get actionClose => 'Tutup';
  @override
  String get actionConfirm => 'Konfirmasi';
  @override
  String get actionDelete => 'Hapus';
  @override
  String get actionEdit => 'Ubah';
  @override
  String get actionAdd => 'Tambah';
  @override
  String get actionSubmit => 'Kirim';
  @override
  String get actionRefresh => 'Muat ulang';
  @override
  String get actionViewAll => 'Lihat semua';
  @override
  String get actionViewDetail => 'Lihat detail';
  @override
  String get actionReadAll => 'Baca semua';
  @override
  String get actionLogout => 'Keluar';
  @override
  String get actionLogin => 'Masuk';
  @override
  String get actionRegister => 'Daftar';
  @override
  String get actionNext => 'Lanjut';
  @override
  String get actionSend => 'Kirim';
  @override
  String get actionApply => 'Ajukan';
  @override
  String get actionUploadGallery => 'Unggah dari Galeri';

  // Labels
  @override
  String get labelLoading => 'Memuat…';
  @override
  String get labelError => 'Terjadi kesalahan';
  @override
  String get labelSuccess => 'Berhasil';
  @override
  String get labelRequired => 'wajib diisi';
  @override
  String get labelOptional => 'opsional';
  @override
  String get errorGenericRetry => 'Terjadi kesalahan. Coba lagi.';
  @override
  String unitMonths(int n) => '$n bulan';
  @override
  String get roofOrientationNorth => 'Menghadap utara';
  @override
  String get roofOrientationEastWest => 'Timur–barat';
  @override
  String get roofOrientationSouth => 'Menghadap selatan';
  @override
  String get roofOrientationFlat => 'Datar (dak)';
  @override
  String get roofOrientationUnknown => 'Tidak tahu';
  @override
  String get roofShadingNone => 'Tidak terhalang';
  @override
  String get roofShadingPartial => 'Sebagian terhalang';
  @override
  String get roofShadingHeavy => 'Banyak terhalang';
  @override
  String get roofBandVeryFeasible => 'Sangat Layak';
  @override
  String get roofBandFeasible => 'Layak';
  @override
  String get roofBandFairlyFeasible => 'Cukup Layak';
  @override
  String get roofBandLessFeasible => 'Kurang Layak';
  @override
  String get roofScanSkipPhoto => 'Lewati foto';
  @override
  String get roofSavingPhotoLabel => 'Menyimpan foto…';
  @override
  String get roofSizeTitle => 'Ukuran Atap';
  @override
  String get roofCalculateAction => 'Hitung potensi';
  @override
  String get roofMeasureHint =>
      'Ukur bagian atap yang bebas dipasang panel. Pakai meteran, atau '
      'hitung langkah kaki: 1 langkah ≈ 0,7 meter.';
  @override
  String get roofLengthLabel => 'Panjang';
  @override
  String get roofWidthLabel => 'Lebar';
  @override
  String roofFieldRequired(String label) => 'Isi $label';
  @override
  String get roofFieldTooLarge => 'Terlalu besar';
  @override
  String roofAreaSummary(String total, String usable) =>
      'Luas $total m² · bisa dipakai ± $usable m²';
  @override
  String get roofOrientationQuestion => 'Atap menghadap ke mana?';
  @override
  String get roofShadingQuestion => 'Apakah terhalang pohon atau bangunan?';
  @override
  String get roofResultTitle => 'Hasil Radar Atap';
  @override
  String get roofSavedLabel => 'Tersimpan';
  @override
  String get roofSaveAction => 'Simpan hasil';
  @override
  String get roofSavedToast => 'Hasil Radar Atap tersimpan.';
  @override
  String get roofPotentialLabel => 'Potensi panel surya';
  @override
  String get roofProductionSection => 'Estimasi Produksi';
  @override
  String get roofUsableArea => 'Luas yang bisa dipakai';
  @override
  String get roofMonthlyEnergy => 'Energi per bulan';
  @override
  String get roofYourLastUsage => 'Pemakaian Anda bulan terakhir';
  @override
  String get roofSavingsSection => 'Estimasi Penghematan';
  @override
  String get roofSavingsPerMonth => 'Hemat per bulan';
  @override
  String get roofSavingsPerYear => 'Hemat per tahun';
  @override
  String get roofCostSection => 'Biaya & Balik Modal';
  @override
  String get roofInstallCost => 'Perkiraan biaya pasang';
  @override
  String get roofPayback => 'Balik modal';
  @override
  String roofPaybackYears(String years) => '± $years tahun';
  @override
  String get threadNotFound => 'Percakapan tidak ditemukan';
  @override
  String get threadMessageHint => 'Tulis pesan…';
  @override
  String get energyKindToken => 'Token Listrik';
  @override
  String get energyKindBill => 'Tagihan Bulanan';
  @override
  String get roofAssumptionsTitle => 'Asumsi yang dipakai';
  @override
  String roofAssumptionsBody(
    String usableFraction,
    String sqmPerKwp,
    String sunHours,
    String performanceRatio,
    String siteFactor,
    String costPerKwp,
    String tariff,
  ) =>
      '• $usableFraction% luas atap bisa dipasang panel\n'
      '• $sqmPerKwp m² atap per 1 kWp panel\n'
      '• $sunHours jam matahari penuh per hari\n'
      '• $performanceRatio% energi tersisa setelah kabel & inverter\n'
      '• Faktor arah dan bayangan: $siteFactor%\n'
      '• Biaya pasang $costPerKwp per kWp (diatur koperasi)\n'
      '• Hemat hanya dihitung sampai sebesar pemakaian Anda, dengan tarif '
      '$tariff/kWh';
  @override
  String get labelStatus => 'Status';
  @override
  String get labelDate => 'Tanggal';
  @override
  String get labelAmount => 'Jumlah';
  @override
  String get labelNote => 'Catatan';
  @override
  String get labelPhone => 'Nomor HP';
  @override
  String get labelName => 'Nama';
  @override
  String get labelCity => 'Kota';
  @override
  String get labelBusinessName => 'Nama usaha';
  @override
  String get labelPin => 'PIN';
  @override
  String get labelNewPin => 'PIN baru';
  @override
  String get labelConfirmPin => 'Konfirmasi PIN';
  @override
  String get labelInviteCode => 'Kode undangan';
  @override
  String get labelSearch => 'Cari';
  @override
  String get labelFilter => 'Filter';
  @override
  String get labelTotal => 'Total';
  @override
  String get labelApproved => 'Disetujui';
  @override
  String get labelRejected => 'Ditolak';
  @override
  String get labelPending => 'Menunggu';
  @override
  String get labelCompleted => 'Selesai';
  @override
  String get labelActive => 'Aktif';
  @override
  String get labelEstimation => 'Estimasi';
  @override
  String get labelSince => 'Sejak';

  // Welcome
  @override
  String get welcomeHeadline => 'Kelola listrik usaha bersama koperasi';
  @override
  String get welcomeFeatureSolar => 'Pesan jadwal pakai Solar Hub koperasi';
  @override
  String get welcomeFeatureArisan =>
      'Arisan energi dan pinjaman usaha dari koperasi';
  @override
  String get welcomeTrySample => 'Coba dengan data contoh';
  @override
  String get welcomeSampleTitle => 'Tambah data contoh?';
  @override
  String get welcomeSampleBanner =>
      'Aplikasi akan membuat "Koperasi Energi Melati" berisi 1 admin dan '
      '4 anggota dengan catatan listrik, arisan, dan pengajuan pinjaman '
      'rekaan. Semua angka di dalamnya bukan data asli. Anda bisa '
      'menghapusnya kapan saja dari menu Tentang.';
  @override
  String get welcomeLoginAs => 'Masuk sebagai';

  // Login
  @override
  String get loginTitle => 'Masuk';
  @override
  String get loginPhonePrompt => 'Nomor HP Anda';
  @override
  String get loginPhoneHint => '0812 3456 7890';
  @override
  String get loginPhoneLabel => 'Nomor HP';
  @override
  String get loginPhoneHelper => 'Pakai nomor yang Anda daftarkan di IbuDaya.';
  @override
  String get loginPhoneError => 'Nomor HP tidak valid. Contoh: 0812 3456 7890';
  @override
  String get loginNoAccount => 'Belum punya akun?';
  @override
  String get loginPinTitle => 'Masukkan PIN';
  @override
  String get loginPinSubtitle => 'Halo, selamat datang kembali';
  @override
  String get loginForgotPin => 'Lupa PIN?';
  @override
  String get loginForgotPinTitle => 'Lupa PIN';
  @override
  String get loginForgotPinBody =>
      'Saat ini akun tersimpan hanya di HP ini, jadi PIN tidak bisa '
      'dikirim ulang. Setelah terhubung ke server koperasi, PIN bisa '
      'diatur ulang lewat SMS.\n\nJika benar-benar lupa, Anda bisa '
      'menghapus semua data di HP ini lalu mendaftar lagi.';
  @override
  String get loginClearData => 'Hapus data';
  @override
  String get loginClearDataConfirmTitle => 'Hapus semua data?';
  @override
  String get loginClearDataConfirmBody =>
      'Semua akun, catatan listrik, arisan, dan pinjaman di HP '
      'ini akan hilang dan tidak bisa dikembalikan.';
  @override
  String get loginClearDataConfirmLabel => 'Hapus semua';
  @override
  String get loginClearDataSuccess => 'Data di HP ini sudah dihapus.';
  @override
  String get loginUnderstood => 'Mengerti';

  // Register
  @override
  String get registerTitle => 'Daftar';
  @override
  String get registerPrompt => 'Anda mendaftar sebagai?';
  @override
  String get registerSubtitle =>
      'IbuDaya dipakai bersama koperasi. Setiap anggota bergabung '
      'dengan kode dari admin koperasinya.';
  @override
  String get registerAsMember => 'Anggota koperasi';
  @override
  String get registerMemberBody =>
      'Saya punya usaha dan sudah mendapat kode koperasi dari admin.';
  @override
  String get registerMemberCta => 'Daftar sebagai anggota';
  @override
  String get registerAsAdmin => 'Admin koperasi';
  @override
  String get registerAdminBody =>
      'Saya pengurus koperasi. Saya akan membuat koperasi, mengelola '
      'anggota, Solar Hub, arisan, dan meninjau pinjaman.';
  @override
  String get registerAdminCta => 'Buat koperasi';
  @override
  String get registerHaveAccount => 'Sudah punya akun?';

  // Register Member
  @override
  String get registerMemberTitle => 'Daftar Anggota';
  @override
  String get registerMemberStep0Title => 'Masukkan kode koperasi';
  @override
  String get registerMemberStep0Subtitle =>
      'Kode 6 huruf/angka ini diberikan oleh admin koperasi Anda.';
  @override
  String get registerMemberCodeHint => 'KODE';
  @override
  String get registerMemberCodeError =>
      'Kode tidak ditemukan. Periksa lagi atau tanyakan ke admin.';
  @override
  String get registerMemberJoiningTo => 'Bergabung ke';
  @override
  String get registerMemberFieldName => 'Nama lengkap';
  @override
  String get registerMemberFieldNameHint => 'Contoh: Clara Wulandari';
  @override
  String get registerMemberFieldBusiness => 'Nama usaha';
  @override
  String get registerMemberFieldBusinessHint => 'Contoh: Katering Clara';
  @override
  String get registerMemberFieldCity => 'Kota';
  @override
  String get registerMemberFieldPhone => 'Nomor HP';
  @override
  String get registerMemberFieldPhoneHelper =>
      'Dipakai untuk masuk ke aplikasi.';
  @override
  String get registerMemberFieldPhoneError => 'Nomor HP tidak valid.';
  @override
  String get registerMemberSuccess => 'Selamat bergabung';
  @override
  String registerMemberSuccessNamed(String coopName) =>
      'Selamat bergabung di $coopName!';
  @override
  String get registerMemberGenericCoop => 'koperasi';

  // Register Admin
  @override
  String get registerAdminTitle => 'Buat Koperasi';
  @override
  String get registerAdminCoopName => 'Nama koperasi';
  @override
  String get registerAdminCoopNameHint => 'Contoh: Koperasi Energi Melati';
  @override
  String get registerAdminCoopCity => 'Kota koperasi';
  @override
  String get registerAdminPinCreated => 'Koperasi berhasil dibuat.';
  @override
  String get registerStepPerson => 'Data diri';
  @override
  String get registerStepCoop => 'Koperasi';
  @override
  String get registerStepCode => 'Kode';
  @override
  String get registerAdminSectionPerson => 'Data pengurus';
  @override
  String get registerAdminCoopHeading => 'Koperasi Anda';
  @override
  String get registerAdminAfterTitle => 'Setelah ini';
  @override
  String get registerAdminAfterBody =>
      'Anda mendapat kode koperasi untuk dibagikan ke anggota. Atur '
      'kapasitas Solar Hub dan kebijakan pinjaman di menu Lainnya → '
      'Pengaturan koperasi.';
  @override
  String get registerAdminLegalWarning =>
      'Pinjaman ke anggota harus dijalankan oleh koperasi yang berbadan '
      'hukum dan berizin simpan pinjam. Aplikasi hanya membantu mencatat '
      'dan meninjau.';
  @override
  String fieldRequired(String label) => '$label wajib diisi.';

  // Sample
  @override
  String get sampleTitle => 'Data contoh';
  @override
  String get sampleMessage =>
      'Semua akun di bawah memakai PIN ${_SamplePin.pin}. '
      'Isinya rekaan untuk mencoba aplikasi.';
  @override
  String get sampleConfirmLabel => 'Tambahkan';

  // Scaffold titles
  @override
  String get scaffoldProfile => 'Profil';
  @override
  String get scaffoldNotifications => 'Notifikasi';
  @override
  String get scaffoldEnergy => 'Catatan Listrik';
  @override
  String get scaffoldEnergyAdd => 'Tambah Catatan';
  @override
  String get scaffoldEnergyAnalysis => 'Analisis Energi';
  @override
  String get scaffoldAppliances => 'Alat Usaha';
  @override
  String get scaffoldApplianceEdit => 'Ubah Alat';
  @override
  String get scaffoldRoof => 'Estimasi Atap Surya';
  @override
  String get scaffoldBooking => 'Pesan Slot Hub';
  @override
  String get scaffoldBookings => 'Jadwal Solar Hub';
  @override
  String get scaffoldArisan => 'Arisan Koperasi';
  @override
  String get scaffoldQuota => 'Pasar Kuota';
  @override
  String get scaffoldQuotaNew => 'Buat Penawaran';
  @override
  String get scaffoldScore => 'Skor Kredit Energi';
  @override
  String get scaffoldLoans => 'Pembiayaan';
  @override
  String get scaffoldLoanDetail => 'Detail Pembiayaan';
  @override
  String get scaffoldLoanApply => 'Ajukan Pembiayaan';
  @override
  String get scaffoldMessages => 'Pesan';
  @override
  String get scaffoldThread => 'Percakapan';
  @override
  String get scaffoldProfileEdit => 'Ubah Profil';
  @override
  String get scaffoldChangePin => 'Ganti PIN';
  @override
  String get scaffoldAbout => 'Tentang IbuDaya';
  @override
  String get scaffoldLanguage => 'Bahasa';
  @override
  String get scaffoldAdminDashboard => 'Dasbor Admin';
  @override
  String get scaffoldAdminLoans => 'Pengajuan Pinjaman';
  @override
  String get scaffoldAdminMembers => 'Anggota';
  @override
  String get scaffoldAdminOther => 'Lainnya';
  @override
  String get scaffoldAdminPayments => 'Konfirmasi Setoran';
  @override
  String get scaffoldAdminArisan => 'Grup Arisan';
  @override
  String get scaffoldAdminHub => 'Solar Hub & Slot';
  @override
  String get scaffoldAdminAnnounce => 'Kirim Pengumuman';
  @override
  String get scaffoldAdminSettings => 'Pengaturan Koperasi';

  // Home
  @override
  String greetingName(String name) => 'Halo, $name';
  @override
  String get homeHelloPrefix => 'Halo';
  @override
  String get homeBillLabel => 'Tagihan listrik';
  @override
  String billMonthLabel(String month) => 'Listrik $month';
  @override
  String get homeBillNoData => 'Belum ada catatan';
  @override
  String get homeBillNoDataHint =>
      'Foto tagihan atau struk token PLN Anda. Angkanya dibaca '
      'otomatis, lalu Anda periksa.';
  @override
  String get homeChangePctSuffix => '% dari bulan lalu';
  @override
  String get homeAnalysis => 'Analisis';
  @override
  String get homeStatusHeader => 'Status Penggunaan Daya';
  @override
  String get homeBookingHub => 'Booking Hub';
  @override
  String get homeArisanEnergi => 'Arisan Koperasi';
  @override
  String get homeTukarKuota => 'Arisan Energi';
  @override
  String get homeSkorKredit => 'Skor Kredit';
  @override
  String get homePembiayaan => 'Pembiayaan';
  @override
  String get homeCatatanListrik => 'Catatan Listrik';
  @override
  String get homeAlatUsaha => 'Alat Usaha';
  @override
  String get homeScoreNotReady => 'Skor Kredit Energi';
  @override
  String homeScoreMonthsNeeded(int n) =>
      'Catat $n bulan lagi agar skor bisa dihitung.';
  @override
  String get homeScoreTitle => 'Skor Kredit Energi';
  @override
  String homeLoanCanApply(String amount) => 'Bisa ajukan hingga $amount';
  @override
  String homeLoanInstallment(int seq, String amount, String date) =>
      'Cicilan ke-$seq $amount · jatuh tempo $date';
  @override
  String get homeLoanOverdue => 'lewat jatuh tempo';
  @override
  String get homeLoanDue => 'jatuh tempo';
  @override
  String get homeImpactTitle => 'Dampak Solar Hub Anda';
  @override
  String get homeImpactThisMonth => 'Hemat bulan ini';
  @override
  String get homeImpactSolarEnergy => 'Energi surya';
  @override
  String get homeImpactCo2 => 'CO₂ dihindari';
  @override
  String get homeImpactCo2Note =>
      'CO₂ memakai asumsi 0,87 kg per kWh listrik PLN. Hemat dihitung '
      'dari energi hub yang sudah Anda tandai terpakai × tarif Anda.';
  @override
  String homeFromTokens(int count) => 'dari $count token';

  // Profile
  @override
  String get profileTitle => 'Profil';
  @override
  String get profileMonthsRecorded => 'Bulan tercatat';
  @override
  String get profileSinceJoined => 'Sejak bergabung';
  @override
  String get profileHubSessions => 'Sesi hub';
  @override
  String get profileHubActivities => 'Aktivitas di Solar Hub';
  @override
  String get profileEnergyCredit => 'Skor Kredit Energi';
  @override
  String get profileCategory => 'Kategori: ';
  @override
  String get profileSectionBusiness => 'Usaha & energi';
  @override
  String get profileMenuEnergy => 'Catatan listrik';
  @override
  String get profileMenuAppliances => 'Alat usaha';
  @override
  String get profileMenuSolarSchedule => 'Jadwal Solar Hub';
  @override
  String get profileMenuScore => 'Skor Kredit Energi';
  @override
  String get profileMenuLoans => 'Pembiayaan';
  @override
  String get profileSectionAccount => 'Akun';
  @override
  String get profileMenuEditProfile => 'Ubah profil & tarif listrik';
  @override
  String get profileMenuChangePin => 'Ganti PIN';
  @override
  String get profileMenuNotifications => 'Notifikasi';
  @override
  String get profileMenuAbout => 'Tentang IbuDaya';
  @override
  String get profileMenuLanguage => 'Bahasa';
  @override
  String get profileLogout => 'Keluar';
  @override
  String get profileLogoutTitle => 'Keluar dari akun?';
  @override
  String get profileLogoutMessage =>
      'Data tetap tersimpan. Masuk lagi dengan nomor HP dan PIN.';
  @override
  String get profileLogoutConfirm => 'Keluar';

  // Language
  @override
  String get languageTitle => 'Bahasa';
  @override
  String get languageSubtitle => 'Pilih bahasa tampilan';
  @override
  String get languageId => 'Bahasa Indonesia';
  @override
  String get languageEn => 'English';

  // Energy
  @override
  String get energyTitle => 'Catatan Listrik';
  @override
  String get energyEmpty => 'Belum ada catatan';
  @override
  String get energyEmptyMessage =>
      'Catatan muncul otomatis setelah sesi Solar Hub Anda selesai dikonfirmasi admin.';
  @override
  String get energyAutoNote =>
      'Dicatat otomatis oleh Solar Hub. Jika ada yang tidak sesuai, hubungi admin koperasi.';
  @override
  String get energyMonth => 'Bulan';
  @override
  String get energyKwh => 'kWh';
  @override
  String get energyBill => 'Tagihan';
  @override
  String get energyTariff => 'Tarif';
  @override
  String get energySourceHub => 'Otomatis (Hub)';
  @override
  String get energySourceManual => 'Manual';
  @override
  String get energySaveSuccess => 'Catatan listrik disimpan.';
  @override
  String get energyAnalysisTitle => 'Analisis Energi';
  @override
  String get energyAnalysisEmpty => 'Data tidak cukup';
  @override
  String get energyAnalysisNoAppliances => 'Belum ada alat usaha yang dicatat.';
  @override
  String get energyAnalysisTrend => 'Tren Pemakaian';
  @override
  String get energyAnalysisContributors => 'Kontributor Daya';

  @override
  String get scanAnalysisSubtitle =>
      'IbuDaya menemukan biaya listrik usaha yang bisa dihemat.';
  @override
  String get scanAnalysisHelpOk => 'Mengerti';
  @override
  String get scanAnalysisHelpTooltip => 'Bantuan Analisis';
  @override
  String get scanAnalysisAppliancesSectionTitle => 'Alat Penyumbang Biaya';
  @override
  String get scanAnalysisPerMonthSuffix => '/ bln';
  @override
  String get scanAnalysisInsightTitle => 'Insight Utama';
  @override
  String get scanAnalysisEmptyMessage =>
      'Pakai Solar Hub agar catatan listrik Anda mulai tercatat, lalu lihat analisisnya di sini.';
  @override
  String get scanAnalysisCtaSolarHub => 'Lihat Jadwal Solar Hub';
  @override
  String get energyAnalysisUseSolarHub => 'Pakai Solar Hub';
  @override
  String get scanAnalysisLoadingSubtitle =>
      'Mohon tunggu sebentar, sistem sedang memproses data tagihan...';
  @override
  String get scanAnalysisLoadingBadge => 'Analisis Energi';
  @override
  String get scanStep1 => 'Membaca data tagihan...';
  @override
  String get scanStep2 => 'Menganalisis pola penggunaan energi...';
  @override
  String get scanStep3 => 'Mengidentifikasi sumber biaya terbesar...';
  @override
  String get scanStep4 => 'Menyusun rekomendasi penghematan...';
  @override
  String get scanStep5 => 'Analisis selesai';

  // Appliances
  @override
  String get appliancesTitle => 'Alat Usaha';
  @override
  String get appliancesEmpty => 'Belum ada alat';
  @override
  String get appliancesEmptyMessage =>
      'Tambahkan alat usaha untuk melihat estimasi konsumsi energinya.';
  @override
  String get appliancesAdd => 'Tambah alat';
  @override
  String get applianceFormTitle => 'Alat Usaha';
  @override
  String get applianceFormName => 'Nama alat';
  @override
  String get applianceFormWatt => 'Daya (Watt)';
  @override
  String get applianceFormHoursPerDay => 'Jam per hari';
  @override
  String get applianceFormDaysPerWeek => 'Hari per minggu';
  @override
  String get applianceFormCategory => 'Kategori';
  @override
  String get applianceSaveSuccess => 'Alat berhasil disimpan.';
  @override
  String get applianceDeleteConfirmTitle => 'Hapus alat?';
  @override
  String get scaffoldApplianceAdd => 'Tambah Alat';
  @override
  String get applianceDeleteConfirmMessage =>
      'Alat ini tidak lagi dihitung dalam analisis listrik.';
  @override
  String get applianceDeletedToast => 'Alat dihapus.';
  @override
  String get applianceFormNameRequired => 'Isi nama alat.';
  @override
  String get applianceFormWattRequired => 'Isi daya dalam watt.';
  @override
  String get applianceFormWattTooLarge =>
      'Terlalu besar untuk alat rumah tangga.';
  @override
  String get applianceFormWattHelper =>
      'Lihat stiker di belakang alat. Angka awal adalah ukuran umum.';
  @override
  String get applianceMonthlyLabel => 'Per bulan';
  @override
  String get applianceMonthlyCostLabel => 'Biaya';
  @override
  String applianceHoursValue(String hours) => '$hours jam';

  @override
  String get captureTorchOn => 'Nyalakan lampu';
  @override
  String get captureTorchOff => 'Matikan lampu';
  @override
  String get captureCameraNotFound => 'Kamera tidak ditemukan di HP ini.';
  @override
  String get captureCameraDenied =>
      'Izin kamera ditolak. Aktifkan di Pengaturan HP, atau pilih foto dari galeri.';
  @override
  String get captureCameraUnavailable =>
      'Kamera tidak bisa dibuka. Pilih foto dari galeri.';
  @override
  String get captureShootFailed => 'Gagal mengambil foto. Coba lagi.';
  @override
  String get captureGalleryFailed => 'Galeri tidak bisa dibuka.';
  @override
  String get captureGalleryLabel => 'Galeri';
  @override
  String get captureShootSemanticLabel => 'Ambil foto';
  @override
  String get captureDefaultBusyLabel => 'Memproses…';

  // Solar
  @override
  String get solarTitle => 'Solar Hub';
  @override
  String get solarNoHub => 'Hub belum tersedia';
  @override
  String get solarNoHubMessage =>
      'Admin koperasi belum mengatur Solar Hub. Hubungi admin.';
  @override
  String get solarCapacity => 'Kapasitas';
  @override
  String get solarBook => 'Pesan slot';
  @override
  String get solarMyBookings => 'Jadwal saya';
  @override
  String get solarSlotAvailable => 'Tersedia';
  @override
  String get solarSlotFull => 'Penuh';
  @override
  String get solarBookingTitle => 'Pesan Slot Hub';
  @override
  String get solarBookingAppliance => 'Alat yang dipakai';
  @override
  String get solarBookingDate => 'Tanggal';
  @override
  String get solarBookingSlot => 'Slot waktu';
  @override
  String get solarBookingConfirm => 'Konfirmasi Booking';
  @override
  String get solarBookingSuccess => 'Booking berhasil dibuat.';
  @override
  String get solarBookingsTitle => 'Jadwal Solar Hub';
  @override
  String get solarBookingsEmpty => 'Belum ada jadwal';
  @override
  String get solarRoofTitle => 'Estimasi Atap Surya';
  @override
  String get solarRoofHint => 'Foto atap yang ingin dipasang panel surya';
  @override
  String get solarRoofTip1 => 'Seluruh atap terlihat';
  @override
  String get solarRoofTip2 => 'Siang hari, cahaya cukup';
  @override
  String get solarRoofCapture => 'Foto atap Anda';
  @override
  String get solarRoofAnalysing => 'Menganalisis…';
  @override
  String get solarRoofResult => 'Estimasi Hasil';

  // Arisan
  @override
  String get arisanTitle => 'Arisan Koperasi';
  @override
  String get arisanNoGroup => 'Belum bergabung grup arisan';
  @override
  String get arisanNoGroupMessage =>
      'Admin koperasi akan menambahkan Anda ke grup arisan.';
  @override
  String get arisanGroupName => 'Nama grup';
  @override
  String get arisanCycle => 'Siklus';
  @override
  String get arisanDues => 'Iuran';
  @override
  String get arisanPay => 'Bayar iuran';
  @override
  String get arisanHistory => 'Riwayat pembayaran';
  @override
  String get arisanQuota => 'Kuota Solar Hub';
  @override
  String get arisanQuotaTitle => 'Pasar Kuota';
  @override
  String get arisanQuotaEmpty => 'Tidak ada penawaran aktif';
  @override
  String get arisanQuotaNew => 'Buat penawaran';
  @override
  String get arisanQuotaNeed => 'Butuh kuota';
  @override
  String get arisanQuotaShare => 'Bagikan kuota';
  @override
  String get arisanQuotaAmount => 'Jumlah kuota (jam)';

  // Score
  @override
  String get scoreFactors => 'Yang membentuk skor Anda';
  @override
  String get scoreAbout => 'Tentang skor ini';
  @override
  String get scoreAboutBody =>
      'Skor Kredit Energi adalah hitungan aturan tetap dari catatan Anda '
      'di IbuDaya: kestabilan pemakaian listrik (35 poin), ketepatan bayar '
      'iuran dan cicilan (30), aktivitas usaha (20), dan keaktifan di '
      'komunitas (15). Ini bukan skor bank atau BI Checking.';
  @override
  String get scoreApply => 'Ajukan Pembiayaan';
  @override
  String get scoreViewLoans => 'Lihat Pembiayaan';
  @override
  String get scoreCanApply => 'Skor mendukung pengajuan';
  @override
  String scoreCanApplyAmount(String amount) =>
      'Skor Anda mendukung pengajuan hingga $amount';
  @override
  String get scoreDecision => 'Keputusan tetap di tangan admin koperasi.';
  @override
  String scoreWithBand(int score, String band) => 'Skor $score · $band';
  @override
  String get scoreShortLabel => 'Skor';
  @override
  String get scoreHistoryTitle => 'Riwayat skor';
  @override
  String scoreUpdatedAt(String when) => 'Diperbarui $when';

  // Loans
  @override
  String get loansTitle => 'Pembiayaan';
  @override
  String get loansEmpty => 'Belum ada pengajuan';
  @override
  String get loansEmptyMessage =>
      'Ajukan pembiayaan jika skor kredit Anda mencukupi.';
  @override
  String get loansApply => 'Ajukan Pembiayaan';
  @override
  String get loanApplyTitle => 'Ajukan Pembiayaan';
  @override
  String get loanApplyAmount => 'Jumlah pinjaman';
  @override
  String get loanApplyTenor => 'Tenor (bulan)';
  @override
  String get loanApplyPurpose => 'Tujuan penggunaan';
  @override
  String get loanApplyConfirm => 'Konfirmasi Pengajuan';
  @override
  String get loanApplySuccess => 'Pengajuan berhasil dikirim.';
  @override
  String get loanDetailTitle => 'Detail Pembiayaan';
  @override
  String get loanStatus => 'Status';
  @override
  String get loanAmount => 'Jumlah';
  @override
  String get loanInstallments => 'Jadwal cicilan';
  @override
  String get loanApprovedBy => 'Disetujui oleh';
  @override
  String get loanDisbursedOn => 'Dicairkan pada';
  @override
  String get loanToastInReview => 'Status: sedang direview.';
  @override
  String get loanToastApproved => 'Pengajuan disetujui.';
  @override
  String get loanToastDisbursed => 'Pencairan dicatat.';
  @override
  String get loanToastCancelled => 'Pengajuan dibatalkan.';
  @override
  String get loanToastRejected => 'Pengajuan ditolak.';
  @override
  String get loanToastInstallmentRecorded => 'Cicilan dicatat.';
  @override
  String get paymentToastRejected => 'Setoran ditolak.';
  @override
  String get paymentToastConfirmed => 'Dikonfirmasi.';

  // Messages
  @override
  String get messagesTitle => 'Pesan';
  @override
  String get messagesEmpty => 'Belum ada pesan';
  @override
  String get messagesEmptyMessage =>
      'Percakapan dengan admin koperasi akan muncul di sini.';
  @override
  String get threadTitle => 'Percakapan';
  @override
  String get threadReply => 'Balas…';
  @override
  String get threadSend => 'Kirim';

  // Notifications
  @override
  String get notificationsTitle => 'Notifikasi';
  @override
  String get notificationsEmpty => 'Belum ada notifikasi';
  @override
  String get notificationsEmptyMessage =>
      'Kabar pengajuan, setoran, dan kuota akan muncul di sini.';
  @override
  String get notificationsReadAll => 'Baca semua';

  // Edit Profile
  @override
  String get editProfileTitle => 'Ubah Profil & Tarif Listrik';
  @override
  String get editProfileName => 'Nama lengkap';
  @override
  String get editProfileBusiness => 'Nama usaha';
  @override
  String get editProfileCity => 'Kota';
  @override
  String get editProfileTariff => 'Tarif listrik (Rp/kWh)';
  @override
  String get editProfileSave => 'Simpan';
  @override
  String get editProfileSuccess => 'Profil berhasil diperbarui.';

  // Change PIN
  @override
  String get changePinTitle => 'Ganti PIN';
  @override
  String get changePinCurrentPin => 'PIN saat ini';
  @override
  String get changePinNewPin => 'PIN baru';
  @override
  String get changePinSuccess => 'PIN berhasil diubah.';

  // About
  @override
  String get aboutTitle => 'Tentang IbuDaya';
  @override
  String get aboutVersion => 'Versi';
  @override
  String get aboutClearSample => 'Hapus data contoh';
  @override
  String get aboutClearSampleConfirmTitle => 'Hapus data contoh?';
  @override
  String get aboutClearSampleConfirmBody =>
      'Koperasi Energi Melati beserta semua anggota dan datanya akan dihapus.';
  @override
  String get aboutClearSampleSuccess => 'Data contoh berhasil dihapus.';
  @override
  String get aboutResetDevice => 'Reset semua data';
  @override
  String get aboutResetDeviceConfirmTitle => 'Hapus semua data?';
  @override
  String get aboutResetDeviceConfirmBody =>
      'Semua akun, catatan, dan data di HP ini akan dihapus permanen.';
  @override
  String get aboutResetDeviceSuccess => 'Data berhasil dihapus.';
  @override
  String get aboutTagline => 'Energi hemat, usaha kuat';
  @override
  String get aboutDescription =>
      'IbuDaya membantu usaha mikro milik perempuan mengelola biaya '
      'listrik, memakai Solar Hub koperasi, ikut arisan energi, dan '
      'mengajukan pinjaman usaha ke koperasinya.';
  @override
  String get aboutNumbersSection => 'Dari mana angka-angkanya';
  @override
  String get aboutNumbersBody =>
      '• Scan tagihan dibaca di HP (Google ML Kit), tidak dikirim ke '
      'internet. Anda selalu memeriksa angkanya sebelum disimpan.\n'
      '• Rincian per alat = watt × jam pakai × tarif Anda. Ini perkiraan.\n'
      '• Skor Kredit Energi memakai aturan tetap dengan 4 faktor yang '
      'terlihat di layar skor. Bukan kecerdasan buatan, bukan skor bank.\n'
      '• Keputusan pinjaman dibuat oleh admin koperasi.\n'
      '• CO₂ memakai asumsi 0,87 kg per kWh listrik PLN.';
  @override
  String get aboutDataStorageSection => 'Penyimpanan data';
  @override
  String get aboutDataStorageBody =>
      'Saat ini semua data tersimpan di HP ini saja. Versi berikutnya '
      'tersambung ke server koperasi agar anggota dan admin bisa saling '
      'melihat data dari HP masing-masing.';
  @override
  String aboutFooter(String teamName) => 'Dibuat oleh tim $teamName.';
  @override
  String get inviteCardFirstMember => 'Undang anggota pertama Anda';
  @override
  String get inviteCardTitle => 'Kode koperasi';
  @override
  String get inviteCardCopyTooltip => 'Salin kode';
  @override
  String inviteCardShareMessage(String coopName, String code) =>
      'Gabung ke $coopName di aplikasi IbuDaya. Pilih Daftar → Anggota '
      'koperasi, lalu masukkan kode $code.';
  @override
  String get inviteCardCopiedToast => 'Pesan undangan disalin.';
  @override
  String get inviteCardCaption =>
      'Anggota memasukkan kode ini saat mendaftar. Jangan sebar ke orang '
      'di luar koperasi.';
  @override
  String arisanQuotaActionConfirmTitle(String action) => '$action kuota?';
  @override
  String get arisanQuotaUpdatedToast => 'Kuota diperbarui.';
  @override
  String get arisanQuotaSentToast => 'Terkirim.';
  @override
  String get bookingCancelledToast => 'Booking dibatalkan.';
  @override
  String get bookingRecordedToast => 'Tercatat.';
  @override
  String solarBookingComeOnTime(String hubName) =>
      'Datang ke $hubName sesuai jadwal.';
  @override
  String get bookingCustomApplianceSublabel => 'Alat kustom';
  @override
  String get appliancesMonthlyEstimateLabel => 'Perkiraan per bulan';
  @override
  String loginPinForPhone(String phone) => 'Masukkan PIN untuk $phone';

  // Admin Dashboard
  @override
  String get adminDashTitle => 'Dasbor Admin';
  @override
  String get adminMembers => 'Anggota';
  @override
  String get adminSectionManage => 'Kelola koperasi';
  @override
  String get adminPaymentsMenu => 'Konfirmasi setoran arisan';
  @override
  String get adminArisanMenu => 'Grup arisan';
  @override
  String get adminHubMenu => 'Solar Hub & slot';
  @override
  String get adminAnnounceMenu => 'Kirim pengumuman';
  @override
  String get adminMessagesMenu => 'Pesan';
  @override
  String get adminSettingsMenu => 'Pengaturan koperasi & pinjaman';
  @override
  String get adminSettingsSubtitle =>
      'Kode undangan, plafon, jasa, tenor, kuota';
  @override
  String get adminSectionAccount => 'Akun';
  @override
  String get adminEditProfile => 'Ubah profil';
  @override
  String get adminChangePin => 'Ganti PIN';

  @override
  String get adminLoansTitle => 'Pengajuan Pinjaman';
  @override
  String get adminLoansEmpty => 'Tidak ada pengajuan';
  @override
  String get adminLoansEmptyMessage =>
      'Pengajuan pembiayaan anggota akan muncul di sini.';

  @override
  String get adminMembersTitle => 'Anggota';
  @override
  String get adminMembersEmpty => 'Belum ada anggota';
  @override
  String get adminMembersEmptyMessage =>
      'Bagikan kode undangan agar anggota bisa mendaftar.';
  @override
  String get adminMemberDetailTitle => 'Detail Anggota';
  @override
  String get adminMemberNotFound => 'Anggota tidak ditemukan';
  @override
  String get adminMemberSendMessage => 'Kirim pesan';
  @override
  String get adminMemberElectricityLast3Months => 'Listrik 3 bulan terakhir';
  @override
  String get adminMemberLoansSection => 'Pinjaman';
  @override
  String get adminMemberNoLoans => 'Belum pernah mengajukan.';
  @override
  String get adminMemberNoScore => 'Skor belum bisa dihitung';
  @override
  String get adminMemberScorePendingShort => 'Belum ada skor';
  @override
  String get adminMemberArisanSection => 'Arisan';

  @override
  String get adminPaymentsTitle => 'Konfirmasi Setoran';
  @override
  String get adminPaymentsEmpty => 'Tidak ada setoran menunggu';
  @override
  String get adminPaymentsApprove => 'Konfirmasi';
  @override
  String get adminPaymentsReject => 'Tolak';

  @override
  String get adminArisanTitle => 'Grup Arisan';
  @override
  String get adminArisanNewGroup => 'Buat grup baru';
  @override
  String get adminArisanGroupName => 'Nama grup';
  @override
  String get adminArisanDues => 'Iuran per siklus';
  @override
  String get adminArisanCycle => 'Panjang siklus';
  @override
  String get arisanAdminCreateGroupButton => 'Buat grup arisan';
  @override
  String get arisanAdminEmptyTitle => 'Belum ada grup arisan';
  @override
  String get arisanAdminEmptyMessage =>
      'Buat grup, pilih anggotanya, dan tentukan urutan giliran.';
  @override
  String get arisanAdminDuesPerMonth => 'Iuran per bulan';
  @override
  String arisanAdminMemberCount(int n) => '$n orang';
  @override
  String get arisanAdminStartMonth => 'Mulai';
  @override
  String get arisanAdminPaidThisMonth => 'Lunas bulan ini';
  @override
  String arisanAdminDisbursedTo(String name, String amount) =>
      'Sudah dicairkan ke $name ($amount).';
  @override
  String arisanAdminRecordPayoutTo(String name) => 'Catat pencairan ke $name';
  @override
  String get arisanAdminRecordPayoutConfirmTitle => 'Catat pencairan?';
  @override
  String arisanAdminRecordPayoutConfirmMessage(
    String amount,
    String name,
    String month,
  ) => '$amount diserahkan ke $name untuk $month.';
  @override
  String arisanAdminRecordPayoutWarning(int paid, int total) =>
      '\n\nPerhatian: baru $paid dari $total anggota yang lunas.';
  @override
  String get arisanAdminRecordPayoutAction => 'Catat';
  @override
  String get arisanAdminPayoutRecordedToast => 'Pencairan dicatat.';
  @override
  String get arisanAdminTurnOrderSection => 'Urutan giliran';
  @override
  String get arisanAdminCreateTitle => 'Buat Grup Arisan';
  @override
  String arisanAdminCreateButton(int n) => 'Buat grup ($n anggota)';
  @override
  String get arisanAdminGroupNameRequired => 'Isi nama grup.';
  @override
  String get arisanAdminMinAmount => 'Minimal Rp 1.000.';
  @override
  String get arisanAdminStartMonthLabel => 'Bulan mulai';
  @override
  String get arisanAdminPickMembersTitle =>
      'Pilih anggota sesuai urutan giliran';
  @override
  String get arisanAdminPickMembersHint =>
      'Ketuk anggota yang menerima pertama, lalu kedua, dan seterusnya.';
  @override
  String get arisanAdminNeedMoreMembers =>
      'Butuh minimal 2 anggota terdaftar. Bagikan kode koperasi dulu.';
  @override
  String get arisanAdminGroupCreatedToast =>
      'Grup arisan dibuat. Anggota sudah diberi tahu.';
  @override
  String get arisanDrawButton => 'Kocok Undian';
  @override
  String get arisanDrawDialogTitle => 'Mengocok Urutan Giliran';
  @override
  String get arisanDrawHint =>
      'Setiap anggota hanya diundi sekali — yang sudah dapat giliran tidak '
      'ikut diundi lagi sampai semua anggota lain kebagian.';
  @override
  String get arisanDrawInProgress => 'Mengocok…';
  @override
  String arisanDrawSlot(int turn, String name) => 'Giliran ke-$turn: $name';
  @override
  String get arisanDrawRedo => 'Kocok Ulang';
  @override
  String get arisanDrawConfirm => 'Gunakan Urutan Ini';
  @override
  String get arisanDrawCancel => 'Batal';

  @override
  String get adminHubTitle => 'Solar Hub & Slot';
  @override
  String get adminHubCapacity => 'Kapasitas harian (kWh)';
  @override
  String get adminHubSlots => 'Slot waktu';
  @override
  String get hubNotFound => 'Solar Hub tidak ditemukan';
  @override
  String get hubFieldName => 'Nama hub';
  @override
  String get hubFieldNameRequired => 'Isi nama hub.';
  @override
  String get hubFieldLocation => 'Lokasi';
  @override
  String get hubFieldCapacity => 'Kapasitas energi per hari';
  @override
  String get hubFieldCapacityHelper => 'Isi 0 untuk menutup booking sementara.';
  @override
  String get hubFieldCapacityRequired => 'Isi kapasitas.';
  @override
  String get hubCapacityUnknownTitle => 'Belum tahu kapasitasnya?';
  @override
  String get hubCapacityHint => 'Daya panel terpasang';
  @override
  String hubCapacitySuggestion(String kwh) =>
      '≈ $kwh per hari (kWp × 4 jam matahari × 80%)';
  @override
  String get hubCapacityUse => 'Pakai';
  @override
  String get hubFieldWeatherCode => 'Kode wilayah cuaca (BMKG)';
  @override
  String get hubFieldWeatherCodeHelper =>
      'Opsional. Kode wilayah tingkat kelurahan dari data.bmkg.go.id, mis. '
      '16.71.05.1001 — dipakai untuk menampilkan jam produksi terbaik '
      'berbasis cuaca nyata di layar Solar Hub anggota. Kosongkan jika '
      'belum tahu kodenya; panel itu tidak muncul sampai diisi.';
  @override
  String get hubFieldQuota => 'Kuota default tiap anggota per bulan';
  @override
  String get hubFieldQuotaHelper =>
      'Dipakai kalau anggota belum punya alokasi kapasitas sendiri. Atur alokasi per anggota di halaman detail anggota.';
  @override
  String get hubFieldQuotaRequired => 'Isi kuota.';
  @override
  String get hubSlotsSection => 'Slot jam';
  @override
  String get hubAddSlotDialogTitle => 'Tambah slot';
  @override
  String get hubSlotStart => 'Mulai';
  @override
  String get hubSlotEnd => 'Selesai';
  @override
  String get hubSlotAddedToast => 'Slot ditambahkan.';
  @override
  String get hubSlotDeleteTooltip => 'Hapus slot';
  @override
  String hubSlotDeleteConfirmTitle(String label) => 'Hapus slot $label?';
  @override
  String get hubSlotDeleteConfirmMessage =>
      'Slot yang masih punya booking tidak bisa dihapus.';
  @override
  String get hubSlotDeletedToast => 'Slot dihapus.';
  @override
  String hubSlotHours(int hours) => '$hours jam';
  @override
  String get hubBookingsToConfirmSection =>
      'Booking hari ini & belum dikonfirmasi';
  @override
  String get hubBookingMarkUsed => 'Dipakai';
  @override
  String get hubBookingMarkedUsedToast => 'Ditandai sudah dipakai.';
  @override
  String get hubConnectionRequestsSection =>
      'Permintaan koneksi menunggu verifikasi';
  @override
  String get hubConnectionApprove => 'Setujui';
  @override
  String adminSummarySubtitle(int active, int total, int ready, int trades) =>
      '$active/$total aktif · $ready siap pinjam · $trades pertukaran kuota';
  @override
  String get adminSummaryActive => 'Anggota aktif';
  @override
  String get adminSummaryLoanReady => 'Siap pinjam';
  @override
  String get adminSummaryTrades => 'Pertukaran kuota';
  @override
  String get adminSummaryTradedKwh => 'Kuota berpindah';
  @override
  String get adminSummaryUtilization => 'Utilisasi hub';
  @override
  String get adminSummaryUtilizationHint =>
      'Bagian kuota bulanan anggota yang sudah dipakai bulan ini.';
  @override
  String get adminSummaryRepayment => 'Cicilan tepat waktu';
  @override
  String get adminSummaryRepaymentNone => 'Belum ada cicilan yang jatuh tempo.';
  @override
  String adminSummaryRepaymentDetail(int ok, int due) =>
      '$ok dari $due cicilan yang jatuh tempo';
  @override
  String get loanReadyBadge => 'Siap Pinjam';
  @override
  String get adminKpiTitle => 'Ringkasan koperasi';
  @override
  String get adminKpiNote =>
      'Target proposal (95% cicilan tepat waktu, biaya energi turun 37,5%) adalah proyeksi. Hanya angka di atas yang terukur di aplikasi.';
  @override
  String get creditReportTitle => 'Laporan Kredit Energi';
  @override
  String get creditReportOpen => 'Lihat Laporan Kredit Energi';
  @override
  String get creditReportEmpty =>
      'Laporan tersedia setelah skor bisa dihitung (3 bulan tercatat).';
  @override
  String get creditReportIntro =>
      'Ringkasan dari data Solar Hub Anda. Skornya dihitung dengan aturan tetap yang bisa diperiksa, bukan model AI, dan bukan keputusan pinjaman.';
  @override
  String get creditReportCopy => 'Salin laporan';
  @override
  String get creditReportConsentTitle => 'Bagikan laporan ini?';
  @override
  String get creditReportConsentBody =>
      'Laporan berisi skor dan ringkasan pemakaian energi Anda. Salin hanya jika Anda setuju membagikannya kepada lembaga keuangan pilihan Anda.';
  @override
  String get creditReportCopied =>
      'Laporan disalin. Tempel ke pesan untuk lembaga pilihan Anda.';
  @override
  String get creditReportMonths => 'Pemakaian Solar Hub per bulan';
  @override
  String get creditReportActivity => 'Aktivitas 8 minggu terakhir';
  @override
  String creditReportSessions(int n, String kwh) => '$n sesi · $kwh';
  @override
  String get creditReportAppliances => 'Alat usaha terdaftar';
  @override
  String get creditReportQuota => 'Berbagi kuota';
  @override
  String creditReportQuotaValue(int given, int received) =>
      'dibagikan $given · diterima $received';
  @override
  String get creditReportDues => 'Iuran arisan terkonfirmasi';
  @override
  String get creditReportInstallments => 'Cicilan tepat waktu';
  @override
  String creditReportInstallmentsValue(int ok, int due) =>
      '$ok dari $due jatuh tempo';
  @override
  String get creditReportInstallmentsNone => 'belum ada yang jatuh tempo';
  @override
  String get quotaShareToAny => 'Ke siapa saja';
  @override
  String get quotaShareToMember => 'Ke anggota tertentu';
  @override
  String get quotaShareToAnyHint =>
      'Tampil di pasar kuota. Anggota pertama yang mengambil langsung menerimanya.';
  @override
  String get quotaShareToMemberHint =>
      'Dikirim hanya ke anggota yang Anda pilih. Ia bisa menerima atau menolak.';
  @override
  String get quotaPickMember => 'Pilih anggota penerima';
  @override
  String get quotaPickMemberRequired => 'Pilih anggota penerima dulu.';
  @override
  String get quotaGiftIncomingTitle => 'Kuota untuk Anda';
  @override
  String quotaGiftFrom(String name, String kwh) =>
      '$name ingin membagikan $kwh kepada Anda';
  @override
  String get quotaGiftAccept => 'Terima';
  @override
  String get quotaGiftDecline => 'Tolak';
  @override
  String get quotaGiftAcceptedToast => 'Kuota diterima dan tercatat.';
  @override
  String get quotaGiftDeclinedToast => 'Kuota ditolak.';
  @override
  String quotaGiftWaiting(String name) => 'Untuk $name · menunggu jawaban';
  @override
  String quotaGiftSentMessage(String name) =>
      'Terkirim ke $name. Kuota berpindah setelah ia menerimanya.';
  @override
  String get quotaMatchTitle => 'Cocok untuk Anda';
  @override
  String get quotaMatchRule =>
      'Urutan: jumlah yang paling pas, lalu yang paling lama menunggu.';
  @override
  String quotaMatchShareCovers(String kwh) =>
      'Menawarkan $kwh — cukup untuk kebutuhan Anda';
  @override
  String quotaMatchShareShort(String kwh, String missing) =>
      'Menawarkan $kwh — kurang $missing dari kebutuhan Anda';
  @override
  String quotaMatchNeedFits(String kwh) => 'Butuh $kwh — bisa Anda penuhi';
  @override
  String get quotaTradedToast => 'Pertukaran tercatat.';
  @override
  String quotaTradeConfirm(String kwh, String name) =>
      '$kwh dengan $name. Kuota langsung berpindah dan tercatat.';
  @override
  String get quotaLedgerTitle => 'Buku Kuota';
  @override
  String quotaLedgerGave(String name) => 'Dibagi ke $name';
  @override
  String quotaLedgerGot(String name) => 'Diterima dari $name';
  @override
  String get quotaLedgerEmpty => 'Belum ada pertukaran kuota.';
  @override
  String get quotaLedgerNote =>
      'Pertukaran hanya mencatat kesepakatan antaranggota. Listrik tetap mengalir lewat limiter masing-masing.';
  @override
  String get hubConnectSending => 'Mengirim permintaan…';
  @override
  String get hubConnectScanAgain => 'Scan QR lagi';
  @override
  String get hubConnectApprovedTitle => 'Disetujui admin';
  @override
  String get hubConnectApprovedMessage =>
      'Admin sudah menyetujui. Listrik hub mengalir sesuai kapasitas Anda.';
  @override
  String get hubConnectRejectedTitle => 'Ditolak admin';
  @override
  String get hubConnectRejectedMessage =>
      'Permintaan Anda tidak disetujui. Hubungi admin koperasi jika ada pertanyaan.';
  @override
  String get hubConnectDoneTitle => 'Terverifikasi';
  @override
  String get hubConnectDoneMessage =>
      'Listrik hub mengalir sesuai kapasitas Anda. Pemakaian tercatat otomatis di Catatan Listrik.';
  @override
  String get hubConnectBrowse => 'Lihat halaman lain';
  @override
  String get adminRequestsTitle => 'Verifikasi Penggunaan Hub';
  @override
  String get adminRequestsEmpty => 'Tidak ada permintaan yang menunggu.';
  @override
  String get adminRequestsIntro =>
      'Anggota yang memindai QR hub muncul di sini. Setujui hanya jika benar-benar sedang memakai hub.';
  @override
  String get adminRequestsCardTitle => 'Verifikasi penggunaan hub';
  @override
  String get hubConnectionReject => 'Tolak';
  @override
  String get hubConnectionApprovedToast => 'Permintaan disetujui.';
  @override
  String get hubConnectionRejectedToast => 'Permintaan ditolak.';

  @override
  String get hubConnectCta => 'Scan QR Sekarang';
  @override
  String get hubConnectTitle => 'Sambungkan ke Solar Hub';
  @override
  String get hubConnectInstruction =>
      'Arahkan kamera ke kode QR di sambungan hub Anda.';
  @override
  String get hubConnectWrongCode => 'QR ini bukan QR Solar Hub koperasi Anda.';
  @override
  String get hubConnectOffHours => 'Solar Hub sedang di luar jam operasional.';
  @override
  String get hubConnectSentTitle => 'Menunggu verifikasi admin';
  @override
  String get hubConnectSentMessage =>
      'Permintaan Anda sudah dikirim. Admin akan memeriksa dan menyetujuinya.';

  @override
  String get adminMemberHubSection => 'Sambungan Solar Hub';
  @override
  String get adminMemberHubAllocation => 'Alokasi kapasitas hub';
  @override
  String get adminMemberHubAllocationHint => 'Kosongkan untuk pakai default';
  @override
  String get adminMemberHubAllocationHelper =>
      'Kapasitas bulanan khusus anggota ini, dari rating limiter yang '
      'terpasang. Kosongkan untuk memakai kuota default koperasi.';

  @override
  String get adminAnnounceTitle => 'Kirim Pengumuman';
  @override
  String get adminAnnounceMessage => 'Pesan pengumuman';
  @override
  String get adminAnnounceSend => 'Kirim ke semua anggota';
  @override
  String get adminAnnounceSent => 'Pengumuman berhasil dikirim.';
  @override
  String adminAnnounceSendCount(int count) => 'Kirim ke $count anggota';
  @override
  String get adminAnnounceConfirmTitle => 'Kirim pengumuman?';
  @override
  String get adminAnnounceConfirmMessage =>
      'Semua anggota akan mendapat notifikasi.';
  @override
  String get adminAnnounceConfirmSend => 'Kirim';
  @override
  String get adminAnnounceHint =>
      'Contoh: Solar Hub tutup hari Jumat untuk perawatan panel.';
  @override
  String get adminAnnounceHelper =>
      'Tulis singkat dan jelas. Sebutkan tanggal dan jam bila perlu.';
  @override
  String get adminAnnouncePreviousSection => 'Pengumuman sebelumnya';

  @override
  String get adminSettingsTitle => 'Pengaturan Koperasi & Pinjaman';
  @override
  String get adminSettingsInviteCode => 'Kode undangan';
  @override
  String get adminSettingsLoanCeiling => 'Plafon maksimum (Rp)';
  @override
  String get adminSettingsLoanMin => 'Skor minimum pengajuan';
  @override
  String get adminSettingsTenor => 'Tenor maksimum (bulan)';
  @override
  String get adminSettingsInterest => 'Jasa per bulan (%)';
  @override
  String get adminSettingsSave => 'Simpan pengaturan';
  @override
  String get adminSettingsSaved => 'Pengaturan berhasil disimpan.';
  @override
  String get coopSettingsNewCodeButton => 'Buat kode baru';
  @override
  String get coopSettingsNewCodeConfirmTitle => 'Buat kode undangan baru?';
  @override
  String coopSettingsNewCodeConfirmMessage(String oldCode) =>
      'Kode lama $oldCode tidak bisa dipakai lagi. Anggota yang sudah '
      'bergabung tidak terpengaruh.';
  @override
  String get coopSettingsNewCodeToast => 'Kode undangan diganti.';
  @override
  String get coopSettingsNameLabel => 'Nama koperasi';
  @override
  String get coopSettingsNameRequired => 'Isi nama koperasi.';
  @override
  String get coopSettingsArisanSection => 'Setoran arisan';
  @override
  String get coopSettingsBankAccountLabel => 'Rekening bendahara (opsional)';
  @override
  String get coopSettingsBankAccountHelper =>
      'Ditampilkan ke anggota saat menyetor iuran, mis. "BCA 1234567890 '
      'a.n. Koperasi Energi Melati". Kosongkan kalau setoran hanya '
      'diterima tunai — jangan isi kalau rekeningnya belum pasti, supaya '
      'anggota tidak transfer ke tempat yang salah.';
  @override
  String get coopSettingsLoanPolicySection => 'Kebijakan pinjaman';
  @override
  String get coopSettingsLoanPolicyWarning =>
      'Pastikan kebijakan ini sesuai AD/ART dan izin usaha simpan pinjam '
      'koperasi Anda. Perubahan hanya berlaku untuk pengajuan baru.';
  @override
  String get coopSettingsCeilingRequired => 'Minimal Rp 500.000.';
  @override
  String coopSettingsCeilingByScore(String bands) =>
      'Plafon tiap anggota mengikuti skornya: $bands.';
  @override
  String get coopSettingsInterestRequired => 'Isi 0 sampai 5%.';
  @override
  String get coopSettingsTenorRequiredToast => 'Pilih minimal satu tenor.';
  @override
  String get coopSettingsTenorSection => 'Pilihan tenor';

  // ── Extra Localizations ──────────────────────────────────────────────────
  @override
  String monthShort(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ][(month - 1).clamp(0, 11)];
  @override
  String monthLong(int month) => const [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ][(month - 1).clamp(0, 11)];
  @override
  String dayShort(int weekday) => const [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ][(weekday - 1).clamp(0, 6)];
  @override
  String get dateYesterday => 'Kemarin';

  @override
  String get qualifierEstimasi => 'estimasi';
  @override
  String get qualifierEstimasiAwal => 'estimasi awal';
  @override
  String get qualifierSimulasi => 'simulasi';
  @override
  String get qualifierIlustrasi => 'ilustrasi';
  @override
  String get qualifierDataContoh => 'data contoh';
  @override
  String get qualifierDataKomunitas => 'data komunitas';
  @override
  String get qualifierDataLangsung => 'data langsung';

  @override
  String get solarWeatherTitle => 'Jam terbaik untuk produksi hari ini';
  @override
  String solarWeatherReason(int cloudPct, String condition) =>
      'BMKG: $condition, tutupan awan $cloudPct%';
  @override
  String get solarWeatherSource => 'Sumber: BMKG (data.bmkg.go.id)';
  @override
  String solarWeatherScore(int score, int tempC) =>
      'Skor produksi $score/100 · $tempC°C';
  @override
  String get solarWeatherRainNote =>
      'BMKG memperkirakan hujan — skor dikurangi.';
  @override
  String get solarBookingBestWeather => 'Jam terbaik cuaca';
  @override
  String get solarWeatherPassedTitle => 'Jam terbaik hari ini sudah lewat';
  @override
  String get solarWeatherPassedHint => 'Coba lagi besok pagi.';
  @override
  String get solarWeatherTomorrowTitle => 'Jam terbaik untuk produksi besok';

  // Solar panel QR scan (demo)

  @override
  String get creditBandPerluPeningkatan => 'Perlu Peningkatan';
  @override
  String get creditBandCukup => 'Cukup';
  @override
  String get creditBandBaik => 'Baik';
  @override
  String get creditBandBaikSekali => 'Baik Sekali';

  @override
  String get roleAdmin => 'Admin Koperasi';
  @override
  String get roleMember => 'Anggota';

  @override
  String get appliancePresetOven => 'Oven';
  @override
  String get appliancePresetKulkas => 'Kulkas';
  @override
  String get appliancePresetMesinJahit => 'Mesin Jahit';
  @override
  String get appliancePresetBlender => 'Blender';
  @override
  String get appliancePresetRiceCooker => 'Rice Cooker';
  @override
  String get appliancePresetMixer => 'Mixer';
  @override
  String get appliancePresetSetrika => 'Setrika';
  @override
  String get appliancePresetKipasAngin => 'Kipas Angin';
  @override
  String get appliancePresetLainnya => 'Lainnya';

  @override
  String obsSpikeTitle(int pct) => 'Lonjakan pemakaian $pct%';
  @override
  String obsSpikeBodyExtra(String extra) =>
      'Lebih mahal sekitar $extra dibanding bulan lalu.';
  @override
  String get obsSpikeBodyAvg =>
      'Pemakaian bulan ini di atas rata-rata bulan sebelumnya.';
  @override
  String obsSavingTitle(int pct) => 'Pemakaian turun $pct%';
  @override
  String get obsSavingBody => 'Lebih hemat dibanding bulan lalu. Pertahankan!';
  @override
  String get obsMismatchTitle => 'Data alat perlu dicek';
  @override
  String get obsMismatchBody =>
      'Total pemakaian alat melebihi catatan listrik Anda.';
  @override
  String obsTopApplianceTitle(String name) => '$name paling boros';
  @override
  String obsTopApplianceBody(String cost) =>
      '±$cost/bulan. Pindahkan ke jam Solar Hub.';
  @override
  String get obsConfirmBookingTitle => 'Konfirmasi pemakaian hub';
  @override
  String obsConfirmBookingBody(int count) =>
      '$count jadwal sudah lewat. Tandai sudah dipakai agar penghematan tercatat.';
  @override
  String get obsUseHubTitle => 'Pakai Solar Hub bulan ini';
  @override
  String get obsUseHubBody =>
      'Belum ada catatan listrik bulan ini — pakai hub agar tercatat otomatis.';
  @override
  String get obsNoApplianceTitle => 'Daftarkan alat usaha';
  @override
  String get obsNoApplianceBody => 'Supaya tagihan bisa dipecah per alat.';

  @override
  String energyAnalysisUsage(String month) => 'Pemakaian $month';
  @override
  String get energyAnalysisNoPrev =>
      'Catat bulan berikutnya untuk melihat perubahan.';
  @override
  String energyAnalysisUp(int pct, String month, String extra) =>
      'Naik $pct% dari $month$extra';
  @override
  String energyAnalysisDown(int pct, String month) => 'Turun $pct% dari $month';
  @override
  String energyAnalysisMoreExpensive(String extra) => ' · lebih mahal ± $extra';
  @override
  String get energyAnalysisSpikeTitle => 'Lonjakan terdeteksi';
  @override
  String get energyAnalysisSpikeBody =>
      'Bulan ini lebih dari 15% di atas rata-rata 3 bulan sebelumnya. Cek alat yang jam pakainya bertambah.';
  @override
  String get energyAnalysisTrend6Months => 'Tren 6 bulan';
  @override
  String get energyAnalysisBreakdownTitle => 'Rincian per alat';
  @override
  String energyAnalysisMismatchBody(String declared, String actual) =>
      'Total alat ($declared) melebihi pemakaian tercatat ($actual). Periksa watt atau jam pakainya.';
  @override
  String get energyAnalysisUnregistered => 'Belum terdaftar (lampu, dll.)';
  @override
  String get energyAnalysisSavingTipTitle => 'Saran penghematan';
  @override
  String energyAnalysisSavingTipBody(String name, String kwh, String cost) =>
      '$name memakai sekitar $kwh per bulan (± $cost). Pakai di jam Solar Hub koperasi untuk mengurangi tagihan PLN.';
  @override
  String energyAnalysisFormula(String tariff) =>
      'Cara menghitung: watt × jam per hari × hari per minggu × 30/7 ÷ 1000 = kWh per bulan, dikali tarif Anda $tariff/kWh. Angkanya perkiraan dari data alat yang Anda isi.';

  @override
  String get solarHubCoop => 'Solar Hub koperasi';
  @override
  String get solarCapacityToday => 'Kapasitas energi hari ini';
  @override
  String solarCapacityAvailable(String rem, String cap) =>
      'tersedia · $rem dari $cap';
  @override
  String get solarBookingScheduleBtn => 'Booking Jadwal';
  @override
  String get solarQuotaThisMonth => 'Kuota energi bulan ini';
  @override
  String solarQuotaRemaining(String rem) => '$rem tersisa';
  @override
  String solarQuotaAllocationUsed(String alloc, String booked) =>
      'Jatah $alloc · terpakai $booked';
  @override
  String get solarSwap => 'Tukar';
  @override
  String get solarTodaySlots => 'Slot hari ini';
  @override
  String get solarSlotCapacityNote =>
      'Kapasitas per slot dibagi mengikuti perkiraan terik matahari 06.00–18.00: slot siang mendapat bagian lebih besar.';
  @override
  String get solarSlotPassed => 'Lewat';
  @override
  String get solarMyScheduleAll => 'Semua';
  @override
  String get solarNoUpcoming => 'Belum ada jadwal yang akan datang.';

  @override
  String get loanStatusSubmitted => 'Terkirim';
  @override
  String get loanStatusInReview => 'Sedang direview';
  @override
  String get loanStatusApproved => 'Disetujui admin';
  @override
  String get loanStatusRejected => 'Ditolak';
  @override
  String get loanStatusDisbursed => 'Dana dicairkan';
  @override
  String get loanStatusRepaid => 'Lunas';
  @override
  String get loanStatusCancelled => 'Dibatalkan';
  @override
  String get loanPurposeRawMaterial => 'Bahan baku';
  @override
  String get loanPurposeEquipment => 'Alat produksi';
  @override
  String get loanPurposeRenovation => 'Renovasi tempat usaha';
  @override
  String get loanPurposeOther => 'Lainnya';

  @override
  String get paymentStatusPending => 'Menunggu konfirmasi';
  @override
  String get paymentStatusConfirmed => 'Terkonfirmasi';
  @override
  String get paymentStatusRejected => 'Ditolak';
  @override
  String get paymentTypeContribution => 'Setoran iuran';
  @override
  String get paymentTypePayout => 'Pencairan giliran';
  @override
  String get bookingStatusPendingVerification => 'Menunggu verifikasi';
  @override
  String get bookingStatusBooked => 'Terjadwal';
  @override
  String get bookingStatusCompleted => 'Sudah dipakai';
  @override
  String get bookingStatusCancelled => 'Dibatalkan';

  @override
  String get arisanNotJoinedTitle => 'Anda belum ikut arisan';
  @override
  String get arisanNotJoinedMsg =>
      'Grup arisan dibuat oleh admin koperasi. Minta admin memasukkan Anda ke grup.';
  @override
  String get arisanSendMessageToAdmin => 'Kirim pesan ke admin';
  @override
  String get arisanGroupChat => 'Obrolan grup';
  @override
  String get arisanTotalPerMonth => 'Total arisan per bulan';
  @override
  String get arisanDuesLabel => 'Iuran';
  @override
  String get arisanTurnThisMonth => 'Giliran bulan ini';
  @override
  String get arisanYourTurn => 'Giliran Anda';
  @override
  String arisanDuesMonth(String month) => 'Iuran $month';
  @override
  String arisanStartsMonth(String month) => 'Arisan mulai $month.';
  @override
  String get arisanPrevRejected => 'Setoran sebelumnya ditolak';
  @override
  String get arisanPrevRejectedNote => 'Hubungi admin untuk detailnya.';
  @override
  String arisanPayInstruction(String amount) =>
      'Serahkan iuran $amount tunai ke bendahara koperasi, lalu tekan tombol di bawah. Admin akan mengonfirmasi.';
  @override
  String arisanPayInstructionWithBank(String amount, String bankAccount) =>
      'Serahkan iuran $amount tunai ke bendahara koperasi, atau transfer ke $bankAccount. Setelah itu tekan tombol di bawah — admin akan mengonfirmasi.';
  @override
  String get arisanPaidBtn => 'Saya sudah setor';
  @override
  String get arisanPaidSuccess => 'Iuran bulan ini sudah lunas.';
  @override
  String get arisanPaidPending =>
      'Setoran terkirim, menunggu konfirmasi admin.';
  @override
  String arisanPayoutInfo(String name, String amount) =>
      'Arisan bulan ini sudah dicairkan ke $name ($amount).';
  @override
  String get arisanEnergyTrading => 'Arisan Energi';
  @override
  String get arisanEnergyTradingSub =>
      'Bagikan sisa kuota Solar Hub ke sesama anggota, atau minta saat butuh.';
  @override
  String arisanMembersCount(int count) => 'Anggota ($count)';
  @override
  String get arisanMyHistory => 'Riwayat saya';
  @override
  String get arisanPayConfirmTitle => 'Sudah menyerahkan iuran?';
  @override
  String arisanPayConfirmMsg(String amount) =>
      'Tekan "Kirim" hanya jika uang $amount sudah diserahkan ke bendahara. Admin akan mengecek dan mengonfirmasi.';
  @override
  String get arisanYouTag => '(Anda)';
  @override
  String arisanTurnFormat(int turn, String month) =>
      'Giliran ke-$turn · $month';
  @override
  String get arisanReceivingThisMonth => ' · menerima bulan ini';
  @override
  String get arisanNotPaidYet => 'Belum setor';
  @override
  String get arisanPaidStatus => 'Lunas';
  @override
  String get arisanWaitingStatus => 'Menunggu';

  @override
  String get scoreNotCalculatedTitle => 'Skor belum bisa dihitung';
  @override
  String scoreNotCalculatedMsg(int min) =>
      'Skor dihitung dari catatan Anda sendiri. Dengan data kurang dari $min bulan, angkanya belum bisa dipercaya.';
  @override
  String scoreRecordsCount(int current, int min) =>
      'Catatan listrik $current/$min bulan';
  @override
  String get scoreRecordsEnough => 'Catatan listrik cukup';
  @override
  String scoreUseHubMoreMonths(int n) => 'Pakai Solar Hub $n bulan lagi';
  @override
  String get scoreUseHubMoreMonthsSubtitle =>
      'Catatan listrik terisi otomatis setiap sesi Solar Hub selesai.';
  @override
  String get scoreInArisan => 'Sudah ikut arisan';
  @override
  String get scoreJoinArisan => 'Ikut grup arisan koperasi';
  @override
  String scoreAppliancesDeclaredCount(int count) => '$count alat terdaftar';
  @override
  String get scoreRegisterAppliance => 'Daftarkan alat usaha';
  @override
  String get scoreFrom100 => 'dari 100';
  @override
  String get scoreFirstThisMonth => 'Skor pertama Anda bulan ini.';
  @override
  String scoreSameAsMonth(String month) => 'Sama dengan $month.';
  @override
  String scoreDeltaUpFromMonth(int pts, String month) =>
      'Naik $pts poin dari $month.';
  @override
  String scoreDeltaDownFromMonth(int pts, String month) =>
      'Turun $pts poin dari $month.';
  @override
  String loanCeilingTitle(String amount) => 'Plafon Anda $amount';
  @override
  String get loanCannotApply => 'Belum bisa mengajukan';
  @override
  String loanCeilingFromScore(int score, String band) =>
      'Dari skor $score ($band).';
  @override
  String loanCoopPolicy(
    String coop,
    String max,
    String rate,
    String tenors,
    int minScore,
  ) =>
      'Kebijakan $coop: maksimal $max, jasa $rate per bulan (flat), tenor $tenors bulan, skor minimum $minScore.';
  @override
  String get loanMySubmissions => 'Pengajuan saya';
  @override
  String get loanNoSubmissions => 'Belum ada pengajuan.';

  @override
  String get eligibilityNone => 'Anda bisa mengajukan hingga plafon ini.';
  @override
  String get eligibilityNotEnoughHistory =>
      'Pakai Solar Hub minimal 3 bulan agar skor bisa dihitung.';
  @override
  String get eligibilityScoreTooLow =>
      'Skor Anda belum mencapai batas minimum yang ditetapkan koperasi.';
  @override
  String get eligibilityActiveLoan =>
      'Selesaikan pinjaman yang masih berjalan sebelum mengajukan lagi.';
}

// ---------------------------------------------------------------------------
// English
// ---------------------------------------------------------------------------

class _EnStrings extends AppLocalizations {
  const _EnStrings();

  @override
  String get appName => 'IbuDaya';
  @override
  String get appTagline =>
      'Help your business grow more efficiently\nwith affordable energy solutions';

  // Nav
  @override
  String get navHome => 'Home';
  @override
  String get navRecords => 'Records';
  @override
  String get navSolarHub => 'Solar Hub';
  @override
  String get navMessages => 'Messages';
  @override
  String get navProfile => 'Profile';
  @override
  String get navDashboard => 'Dashboard';
  @override
  String get navSubmissions => 'Submissions';
  @override
  String get navMembers => 'Members';
  @override
  String get navOther => 'More';

  // Actions
  @override
  String get actionSave => 'Save';
  @override
  String get actionCancel => 'Cancel';
  @override
  String get actionContinue => 'Continue';
  @override
  String get actionBack => 'Back';
  @override
  String get actionClose => 'Close';
  @override
  String get actionConfirm => 'Confirm';
  @override
  String get actionDelete => 'Delete';
  @override
  String get actionEdit => 'Edit';
  @override
  String get actionAdd => 'Add';
  @override
  String get actionSubmit => 'Submit';
  @override
  String get actionRefresh => 'Refresh';
  @override
  String get actionViewAll => 'View all';
  @override
  String get actionViewDetail => 'View details';
  @override
  String get actionReadAll => 'Mark all as read';
  @override
  String get actionLogout => 'Sign out';
  @override
  String get actionLogin => 'Sign in';
  @override
  String get actionRegister => 'Register';
  @override
  String get actionNext => 'Next';
  @override
  String get actionSend => 'Send';
  @override
  String get actionApply => 'Apply';
  @override
  String get actionUploadGallery => 'Upload from Gallery';

  // Labels
  @override
  String get labelLoading => 'Loading…';
  @override
  String get labelError => 'An error occurred';
  @override
  String get labelSuccess => 'Success';
  @override
  String get labelRequired => 'required';
  @override
  String get labelOptional => 'optional';
  @override
  String get errorGenericRetry => 'Something went wrong. Try again.';
  @override
  String unitMonths(int n) => n == 1 ? '$n month' : '$n months';
  @override
  String get roofOrientationNorth => 'Facing north';
  @override
  String get roofOrientationEastWest => 'East–west';
  @override
  String get roofOrientationSouth => 'Facing south';
  @override
  String get roofOrientationFlat => 'Flat (rooftop deck)';
  @override
  String get roofOrientationUnknown => "Don't know";
  @override
  String get roofShadingNone => 'Unobstructed';
  @override
  String get roofShadingPartial => 'Partially shaded';
  @override
  String get roofShadingHeavy => 'Heavily shaded';
  @override
  String get roofBandVeryFeasible => 'Very Feasible';
  @override
  String get roofBandFeasible => 'Feasible';
  @override
  String get roofBandFairlyFeasible => 'Fairly Feasible';
  @override
  String get roofBandLessFeasible => 'Less Feasible';
  @override
  String get roofScanSkipPhoto => 'Skip photo';
  @override
  String get roofSavingPhotoLabel => 'Saving photo…';
  @override
  String get roofSizeTitle => 'Roof Size';
  @override
  String get roofCalculateAction => 'Calculate potential';
  @override
  String get roofMeasureHint =>
      'Measure the part of the roof free for panels. Use a tape measure, '
      'or count paces: 1 pace ≈ 0.7 meters.';
  @override
  String get roofLengthLabel => 'Length';
  @override
  String get roofWidthLabel => 'Width';
  @override
  String roofFieldRequired(String label) => 'Enter $label';
  @override
  String get roofFieldTooLarge => 'Too large';
  @override
  String roofAreaSummary(String total, String usable) =>
      'Area $total m² · usable ± $usable m²';
  @override
  String get roofOrientationQuestion => 'Which way does the roof face?';
  @override
  String get roofShadingQuestion => 'Is it blocked by trees or buildings?';
  @override
  String get roofResultTitle => 'Roof Radar Result';
  @override
  String get roofSavedLabel => 'Saved';
  @override
  String get roofSaveAction => 'Save result';
  @override
  String get roofSavedToast => 'Roof Radar result saved.';
  @override
  String get roofPotentialLabel => 'Solar panel potential';
  @override
  String get roofProductionSection => 'Estimated Production';
  @override
  String get roofUsableArea => 'Usable area';
  @override
  String get roofMonthlyEnergy => 'Energy per month';
  @override
  String get roofYourLastUsage => 'Your usage last month';
  @override
  String get roofSavingsSection => 'Estimated Savings';
  @override
  String get roofSavingsPerMonth => 'Savings per month';
  @override
  String get roofSavingsPerYear => 'Savings per year';
  @override
  String get roofCostSection => 'Cost & Payback';
  @override
  String get roofInstallCost => 'Estimated install cost';
  @override
  String get roofPayback => 'Payback period';
  @override
  String roofPaybackYears(String years) => '± $years years';
  @override
  String get threadNotFound => 'Conversation not found';
  @override
  String get threadMessageHint => 'Write a message…';
  @override
  String get energyKindToken => 'Electricity Token';
  @override
  String get energyKindBill => 'Monthly Bill';
  @override
  String get roofAssumptionsTitle => 'Assumptions used';
  @override
  String roofAssumptionsBody(
    String usableFraction,
    String sqmPerKwp,
    String sunHours,
    String performanceRatio,
    String siteFactor,
    String costPerKwp,
    String tariff,
  ) =>
      '• $usableFraction% of the roof area can fit panels\n'
      '• $sqmPerKwp m² of roof per 1 kWp of panels\n'
      '• $sunHours full sun hours per day\n'
      '• $performanceRatio% of energy remains after cabling & inverter\n'
      '• Orientation and shading factor: $siteFactor%\n'
      '• Install cost $costPerKwp per kWp (set by the cooperative)\n'
      '• Savings are only counted up to your usage, at a tariff of '
      '$tariff/kWh';
  @override
  String get labelStatus => 'Status';
  @override
  String get labelDate => 'Date';
  @override
  String get labelAmount => 'Amount';
  @override
  String get labelNote => 'Note';
  @override
  String get labelPhone => 'Phone number';
  @override
  String get labelName => 'Name';
  @override
  String get labelCity => 'City';
  @override
  String get labelBusinessName => 'Business name';
  @override
  String get labelPin => 'PIN';
  @override
  String get labelNewPin => 'New PIN';
  @override
  String get labelConfirmPin => 'Confirm PIN';
  @override
  String get labelInviteCode => 'Invite code';
  @override
  String get labelSearch => 'Search';
  @override
  String get labelFilter => 'Filter';
  @override
  String get labelTotal => 'Total';
  @override
  String get labelApproved => 'Approved';
  @override
  String get labelRejected => 'Rejected';
  @override
  String get labelPending => 'Pending';
  @override
  String get labelCompleted => 'Completed';
  @override
  String get labelActive => 'Active';
  @override
  String get labelEstimation => 'Estimate';
  @override
  String get labelSince => 'Since';

  // Welcome
  @override
  String get welcomeHeadline =>
      'Manage your business energy with your cooperative';
  @override
  String get welcomeFeatureSolar =>
      'Book Solar Hub time slots at your cooperative';
  @override
  String get welcomeFeatureArisan =>
      'Energy arisan and business financing from your cooperative';
  @override
  String get welcomeTrySample => 'Try with sample data';
  @override
  String get welcomeSampleTitle => 'Add sample data?';
  @override
  String get welcomeSampleBanner =>
      'The app will create "Koperasi Energi Melati" with 1 admin and '
      '4 members with sample electricity records, arisan, and loan applications. '
      'All figures are fictional. You can remove them anytime from the About menu.';
  @override
  String get welcomeLoginAs => 'Sign in as';

  // Login
  @override
  String get loginTitle => 'Sign In';
  @override
  String get loginPhonePrompt => 'Your phone number';
  @override
  String get loginPhoneHint => '0812 3456 7890';
  @override
  String get loginPhoneLabel => 'Phone number';
  @override
  String get loginPhoneHelper => 'Use the number you registered with IbuDaya.';
  @override
  String get loginPhoneError => 'Invalid phone number. Example: 0812 3456 7890';
  @override
  String get loginNoAccount => "Don't have an account?";
  @override
  String get loginPinTitle => 'Enter PIN';
  @override
  String get loginPinSubtitle => 'Hello, welcome back';
  @override
  String get loginForgotPin => 'Forgot PIN?';
  @override
  String get loginForgotPinTitle => 'Forgot PIN';
  @override
  String get loginForgotPinBody =>
      'Your account is currently stored only on this device, so your PIN '
      'cannot be resent. Once connected to the cooperative server, your PIN '
      'can be reset via SMS.\n\nIf you have completely forgotten it, you can '
      'delete all data on this device and register again.';
  @override
  String get loginClearData => 'Delete data';
  @override
  String get loginClearDataConfirmTitle => 'Delete all data?';
  @override
  String get loginClearDataConfirmBody =>
      'All accounts, electricity records, arisan, and loans on this device '
      'will be permanently deleted and cannot be recovered.';
  @override
  String get loginClearDataConfirmLabel => 'Delete all';
  @override
  String get loginClearDataSuccess =>
      'All data on this device has been deleted.';
  @override
  String get loginUnderstood => 'Got it';

  // Register
  @override
  String get registerTitle => 'Register';
  @override
  String get registerPrompt => 'Registering as?';
  @override
  String get registerSubtitle =>
      'IbuDaya is used together with a cooperative. Each member joins '
      'with an invite code from their cooperative admin.';
  @override
  String get registerAsMember => 'Cooperative member';
  @override
  String get registerMemberBody =>
      'I have a business and have received an invite code from my admin.';
  @override
  String get registerMemberCta => 'Register as a member';
  @override
  String get registerAsAdmin => 'Cooperative admin';
  @override
  String get registerAdminBody =>
      'I manage a cooperative. I will create the cooperative, manage '
      'members, Solar Hub, arisan, and review financing applications.';
  @override
  String get registerAdminCta => 'Create cooperative';
  @override
  String get registerHaveAccount => 'Already have an account?';

  // Register Member
  @override
  String get registerMemberTitle => 'Member Registration';
  @override
  String get registerMemberStep0Title => 'Enter cooperative code';
  @override
  String get registerMemberStep0Subtitle =>
      'This 6-character code is given to you by your cooperative admin.';
  @override
  String get registerMemberCodeHint => 'CODE';
  @override
  String get registerMemberCodeError =>
      'Code not found. Please check again or ask your admin.';
  @override
  String get registerMemberJoiningTo => 'Joining';
  @override
  String get registerMemberFieldName => 'Full name';
  @override
  String get registerMemberFieldNameHint => 'Example: Clara Wulandari';
  @override
  String get registerMemberFieldBusiness => 'Business name';
  @override
  String get registerMemberFieldBusinessHint => 'Example: Clara Catering';
  @override
  String get registerMemberFieldCity => 'City';
  @override
  String get registerMemberFieldPhone => 'Phone number';
  @override
  String get registerMemberFieldPhoneHelper => 'Used to sign in to the app.';
  @override
  String get registerMemberFieldPhoneError => 'Invalid phone number.';
  @override
  String get registerMemberSuccess => 'Welcome to the cooperative!';
  @override
  String registerMemberSuccessNamed(String coopName) => 'Welcome to $coopName!';
  @override
  String get registerMemberGenericCoop => 'the cooperative';

  // Register Admin
  @override
  String get registerAdminTitle => 'Create Cooperative';
  @override
  String get registerAdminCoopName => 'Cooperative name';
  @override
  String get registerAdminCoopNameHint => 'Example: Koperasi Energi Melati';
  @override
  String get registerAdminCoopCity => 'City';
  @override
  String get registerAdminPinCreated => 'Cooperative created successfully.';
  @override
  String get registerStepPerson => 'Personal info';
  @override
  String get registerStepCoop => 'Cooperative';
  @override
  String get registerStepCode => 'Code';
  @override
  String get registerAdminSectionPerson => 'Admin details';
  @override
  String get registerAdminCoopHeading => 'Your cooperative';
  @override
  String get registerAdminAfterTitle => 'After this';
  @override
  String get registerAdminAfterBody =>
      'You get a cooperative code to share with members. Set the Solar '
      'Hub capacity and loan policy under Other → Cooperative settings.';
  @override
  String get registerAdminLegalWarning =>
      'Lending to members must be run by a legally registered '
      'savings-and-loan cooperative. The app only helps record and review.';
  @override
  String fieldRequired(String label) => '$label is required.';

  // Sample
  @override
  String get sampleTitle => 'Sample data';
  @override
  String get sampleMessage =>
      'All accounts below use PIN ${_SamplePin.pin}. '
      'The data is fictional for trying the app.';
  @override
  String get sampleConfirmLabel => 'Add';

  // Scaffold titles
  @override
  String get scaffoldProfile => 'Profile';
  @override
  String get scaffoldNotifications => 'Notifications';
  @override
  String get scaffoldEnergy => 'Electricity Records';
  @override
  String get scaffoldEnergyAdd => 'Add Record';
  @override
  String get scaffoldEnergyAnalysis => 'Energy Analysis';
  @override
  String get scaffoldAppliances => 'Business Appliances';
  @override
  String get scaffoldApplianceEdit => 'Edit Appliance';
  @override
  String get scaffoldRoof => 'Solar Roof Estimate';
  @override
  String get scaffoldBooking => 'Book Hub Slot';
  @override
  String get scaffoldBookings => 'Solar Hub Schedule';
  @override
  String get scaffoldArisan => 'Cooperative Arisan';
  @override
  String get scaffoldQuota => 'Quota Market';
  @override
  String get scaffoldQuotaNew => 'Create Offer';
  @override
  String get scaffoldScore => 'Energy Credit Score';
  @override
  String get scaffoldLoans => 'Financing';
  @override
  String get scaffoldLoanDetail => 'Financing Details';
  @override
  String get scaffoldLoanApply => 'Apply for Financing';
  @override
  String get scaffoldMessages => 'Messages';
  @override
  String get scaffoldThread => 'Conversation';
  @override
  String get scaffoldProfileEdit => 'Edit Profile';
  @override
  String get scaffoldChangePin => 'Change PIN';
  @override
  String get scaffoldAbout => 'About IbuDaya';
  @override
  String get scaffoldLanguage => 'Language';
  @override
  String get scaffoldAdminDashboard => 'Dashboard';
  @override
  String get scaffoldAdminLoans => 'Loan Applications';
  @override
  String get scaffoldAdminMembers => 'Members';
  @override
  String get scaffoldAdminOther => 'More';
  @override
  String get scaffoldAdminPayments => 'Payment Confirmation';
  @override
  String get scaffoldAdminArisan => 'Arisan Groups';
  @override
  String get scaffoldAdminHub => 'Solar Hub & Slots';
  @override
  String get scaffoldAdminAnnounce => 'Send Announcement';
  @override
  String get scaffoldAdminSettings => 'Cooperative Settings';

  // Home
  @override
  String greetingName(String name) => 'Hello, $name';
  @override
  String get homeHelloPrefix => 'Hello';
  @override
  String get homeBillLabel => 'Electricity bill';
  @override
  String billMonthLabel(String month) => 'Electricity $month';
  @override
  String get homeBillNoData => 'No records yet';
  @override
  String get homeBillNoDataHint =>
      'Take a photo of your PLN bill or token receipt. '
      'The figures are read automatically for you to verify.';
  @override
  String get homeChangePctSuffix => '% from last month';
  @override
  String get homeAnalysis => 'Analysis';
  @override
  String get homeStatusHeader => 'Power Usage Status';
  @override
  String get homeBookingHub => 'Book Hub';
  @override
  String get homeArisanEnergi => 'Cooperative Arisan';
  @override
  String get homeTukarKuota => 'Arisan Energi';
  @override
  String get homeSkorKredit => 'Credit Score';
  @override
  String get homePembiayaan => 'Financing';
  @override
  String get homeCatatanListrik => 'Electricity Records';
  @override
  String get homeAlatUsaha => 'Appliances';
  @override
  String get homeScoreNotReady => 'Energy Credit Score';
  @override
  String homeScoreMonthsNeeded(int n) =>
      'Record $n more month${n == 1 ? '' : 's'} to calculate your score.';
  @override
  String get homeScoreTitle => 'Energy Credit Score';
  @override
  String homeLoanCanApply(String amount) => 'Eligible to apply up to $amount';
  @override
  String homeLoanInstallment(int seq, String amount, String date) =>
      'Installment #$seq $amount · due $date';
  @override
  String get homeLoanOverdue => 'overdue';
  @override
  String get homeLoanDue => 'due';
  @override
  String get homeImpactTitle => 'Your Solar Hub Impact';
  @override
  String get homeImpactThisMonth => 'Savings this month';
  @override
  String get homeImpactSolarEnergy => 'Solar energy';
  @override
  String get homeImpactCo2 => 'CO₂ avoided';
  @override
  String get homeImpactCo2Note =>
      'CO₂ uses an assumption of 0.87 kg per kWh of PLN electricity. '
      'Savings are calculated from hub energy you have marked as used × your tariff.';
  @override
  String homeFromTokens(int count) =>
      'from $count token${count == 1 ? '' : 's'}';

  // Profile
  @override
  String get profileTitle => 'Profile';
  @override
  String get profileMonthsRecorded => 'Months recorded';
  @override
  String get profileSinceJoined => 'Since joining';
  @override
  String get profileHubSessions => 'Hub sessions';
  @override
  String get profileHubActivities => 'Activity at Solar Hub';
  @override
  String get profileEnergyCredit => 'Energy Credit Score';
  @override
  String get profileCategory => 'Category: ';
  @override
  String get profileSectionBusiness => 'Business & Energy';
  @override
  String get profileMenuEnergy => 'Electricity records';
  @override
  String get profileMenuAppliances => 'Business appliances';
  @override
  String get profileMenuSolarSchedule => 'Solar Hub schedule';
  @override
  String get profileMenuScore => 'Energy Credit Score';
  @override
  String get profileMenuLoans => 'Financing';
  @override
  String get profileSectionAccount => 'Account';
  @override
  String get profileMenuEditProfile => 'Edit profile & electricity tariff';
  @override
  String get profileMenuChangePin => 'Change PIN';
  @override
  String get profileMenuNotifications => 'Notifications';
  @override
  String get profileMenuAbout => 'About IbuDaya';
  @override
  String get profileMenuLanguage => 'Language';
  @override
  String get profileLogout => 'Sign out';
  @override
  String get profileLogoutTitle => 'Sign out of your account?';
  @override
  String get profileLogoutMessage =>
      'Your data will be kept. Sign in again with your phone number and PIN.';
  @override
  String get profileLogoutConfirm => 'Sign out';

  // Language
  @override
  String get languageTitle => 'Language';
  @override
  String get languageSubtitle => 'Select display language';
  @override
  String get languageId => 'Bahasa Indonesia';
  @override
  String get languageEn => 'English';

  // Energy
  @override
  String get energyTitle => 'Electricity Records';
  @override
  String get energyEmpty => 'No records yet';
  @override
  String get energyEmptyMessage =>
      'Records appear automatically after your Solar Hub session is confirmed by the admin.';
  @override
  String get energyAutoNote =>
      'Recorded automatically by the Solar Hub. If something looks wrong, contact your cooperative admin.';
  @override
  String get energyMonth => 'Month';
  @override
  String get energyKwh => 'kWh';
  @override
  String get energyBill => 'Bill';
  @override
  String get energyTariff => 'Tariff';
  @override
  String get energySourceHub => 'Automatic (Hub)';
  @override
  String get energySourceManual => 'Manual';
  @override
  String get energySaveSuccess => 'Electricity record saved.';
  @override
  String get energyAnalysisTitle => 'Energy Analysis';
  @override
  String get energyAnalysisEmpty => 'Insufficient data';
  @override
  String get energyAnalysisNoAppliances =>
      'No business appliances have been recorded.';
  @override
  String get energyAnalysisTrend => 'Usage Trend';
  @override
  String get energyAnalysisContributors => 'Power Contributors';

  @override
  String get scanAnalysisSubtitle =>
      'IbuDaya found business electricity costs you could save on.';
  @override
  String get scanAnalysisHelpOk => 'Got it';
  @override
  String get scanAnalysisHelpTooltip => 'Analysis help';
  @override
  String get scanAnalysisAppliancesSectionTitle =>
      'Cost-Contributing Appliances';
  @override
  String get scanAnalysisPerMonthSuffix => '/ mo';
  @override
  String get scanAnalysisInsightTitle => 'Key Insight';
  @override
  String get scanAnalysisEmptyMessage =>
      'Use the Solar Hub to start recording your electricity usage, then see its analysis here.';
  @override
  String get scanAnalysisCtaSolarHub => 'View Solar Hub Schedule';
  @override
  String get energyAnalysisUseSolarHub => 'Use Solar Hub';
  @override
  String get scanAnalysisLoadingSubtitle =>
      'Please wait, the system is processing your bill data...';
  @override
  String get scanAnalysisLoadingBadge => 'Energy Analysis';
  @override
  String get scanStep1 => 'Reading bill data...';
  @override
  String get scanStep2 => 'Analysing energy usage patterns...';
  @override
  String get scanStep3 => 'Identifying the biggest cost sources...';
  @override
  String get scanStep4 => 'Building savings recommendations...';
  @override
  String get scanStep5 => 'Analysis complete';

  // Appliances
  @override
  String get appliancesTitle => 'Business Appliances';
  @override
  String get appliancesEmpty => 'No appliances yet';
  @override
  String get appliancesEmptyMessage =>
      'Add your business appliances to see their estimated energy consumption.';
  @override
  String get appliancesAdd => 'Add appliance';
  @override
  String get applianceFormTitle => 'Business Appliance';
  @override
  String get applianceFormName => 'Appliance name';
  @override
  String get applianceFormWatt => 'Power (Watts)';
  @override
  String get applianceFormHoursPerDay => 'Hours per day';
  @override
  String get applianceFormDaysPerWeek => 'Days per week';
  @override
  String get applianceFormCategory => 'Category';
  @override
  String get applianceSaveSuccess => 'Appliance saved successfully.';
  @override
  String get applianceDeleteConfirmTitle => 'Delete appliance?';
  @override
  String get scaffoldApplianceAdd => 'Add Appliance';
  @override
  String get applianceDeleteConfirmMessage =>
      'This appliance will no longer count toward the electricity analysis.';
  @override
  String get applianceDeletedToast => 'Appliance deleted.';
  @override
  String get applianceFormNameRequired => 'Enter the appliance name.';
  @override
  String get applianceFormWattRequired => 'Enter the power in watts.';
  @override
  String get applianceFormWattTooLarge =>
      'Too large for a household appliance.';
  @override
  String get applianceFormWattHelper =>
      'Check the sticker on the appliance. The first number is the typical rating.';
  @override
  String get applianceMonthlyLabel => 'Per month';
  @override
  String get applianceMonthlyCostLabel => 'Cost';
  @override
  String applianceHoursValue(String hours) => '$hours hours';

  @override
  String get captureTorchOn => 'Turn on flash';
  @override
  String get captureTorchOff => 'Turn off flash';
  @override
  String get captureCameraNotFound => 'No camera found on this phone.';
  @override
  String get captureCameraDenied =>
      'Camera permission denied. Enable it in phone Settings, or pick a photo from the gallery.';
  @override
  String get captureCameraUnavailable =>
      'Camera can\'t be opened. Pick a photo from the gallery.';
  @override
  String get captureShootFailed => 'Failed to take the photo. Try again.';
  @override
  String get captureGalleryFailed => 'Gallery can\'t be opened.';
  @override
  String get captureGalleryLabel => 'Gallery';
  @override
  String get captureShootSemanticLabel => 'Take photo';
  @override
  String get captureDefaultBusyLabel => 'Processing…';

  // Solar
  @override
  String get solarTitle => 'Solar Hub';
  @override
  String get solarNoHub => 'Hub not yet available';
  @override
  String get solarNoHubMessage =>
      'The cooperative admin has not set up a Solar Hub yet. Contact your admin.';
  @override
  String get solarCapacity => 'Capacity';
  @override
  String get solarBook => 'Book slot';
  @override
  String get solarMyBookings => 'My schedule';
  @override
  String get solarSlotAvailable => 'Available';
  @override
  String get solarSlotFull => 'Full';
  @override
  String get solarBookingTitle => 'Book Hub Slot';
  @override
  String get solarBookingAppliance => 'Appliance to use';
  @override
  String get solarBookingDate => 'Date';
  @override
  String get solarBookingSlot => 'Time slot';
  @override
  String get solarBookingConfirm => 'Confirm Booking';
  @override
  String get solarBookingSuccess => 'Booking created successfully.';
  @override
  String get solarBookingsTitle => 'Solar Hub Schedule';
  @override
  String get solarBookingsEmpty => 'No bookings yet';
  @override
  String get solarRoofTitle => 'Solar Roof Estimate';
  @override
  String get solarRoofHint => 'Photo of the roof for the solar panels';
  @override
  String get solarRoofTip1 => 'The whole roof is visible';
  @override
  String get solarRoofTip2 => 'Daytime, with enough light';
  @override
  String get solarRoofCapture => 'Photo of your roof';
  @override
  String get solarRoofAnalysing => 'Analysing…';
  @override
  String get solarRoofResult => 'Estimate Results';

  // Arisan
  @override
  String get arisanTitle => 'Cooperative Arisan';
  @override
  String get arisanNoGroup => 'Not yet in an arisan group';
  @override
  String get arisanNoGroupMessage =>
      'Your cooperative admin will add you to an arisan group.';
  @override
  String get arisanGroupName => 'Group name';
  @override
  String get arisanCycle => 'Cycle';
  @override
  String get arisanDues => 'Dues';
  @override
  String get arisanPay => 'Pay dues';
  @override
  String get arisanHistory => 'Payment history';
  @override
  String get arisanQuota => 'Solar Hub Quota';
  @override
  String get arisanQuotaTitle => 'Quota Market';
  @override
  String get arisanQuotaEmpty => 'No active offers';
  @override
  String get arisanQuotaNew => 'Create offer';
  @override
  String get arisanQuotaNeed => 'Need quota';
  @override
  String get arisanQuotaShare => 'Share quota';
  @override
  String get arisanQuotaAmount => 'Quota amount (hours)';

  // Score
  @override
  String get scoreFactors => 'What makes up your score';
  @override
  String get scoreAbout => 'About this score';
  @override
  String get scoreAboutBody =>
      'The Energy Credit Score is a fixed-rule calculation from your IbuDaya records: '
      'electricity usage stability (35 points), payment history (30), '
      'business activity (20), and community participation (15). '
      'This is not a bank score or BI Checking.';
  @override
  String get scoreApply => 'Apply for Financing';
  @override
  String get scoreViewLoans => 'View Financing';
  @override
  String get scoreCanApply => 'Score supports application';
  @override
  String scoreCanApplyAmount(String amount) =>
      'Your score supports an application up to $amount';
  @override
  String get scoreDecision =>
      'Final decision remains with the cooperative admin.';
  @override
  String scoreWithBand(int score, String band) => 'Score $score · $band';
  @override
  String get scoreShortLabel => 'Score';
  @override
  String get scoreHistoryTitle => 'Score history';
  @override
  String scoreUpdatedAt(String when) => 'Updated $when';

  // Loans
  @override
  String get loansTitle => 'Financing';
  @override
  String get loansEmpty => 'No applications yet';
  @override
  String get loansEmptyMessage =>
      'Apply for financing if your credit score qualifies.';
  @override
  String get loansApply => 'Apply for Financing';
  @override
  String get loanApplyTitle => 'Apply for Financing';
  @override
  String get loanApplyAmount => 'Loan amount';
  @override
  String get loanApplyTenor => 'Tenor (months)';
  @override
  String get loanApplyPurpose => 'Purpose of use';
  @override
  String get loanApplyConfirm => 'Confirm Application';
  @override
  String get loanApplySuccess => 'Application submitted successfully.';
  @override
  String get loanDetailTitle => 'Financing Details';
  @override
  String get loanStatus => 'Status';
  @override
  String get loanAmount => 'Amount';
  @override
  String get loanInstallments => 'Installment schedule';
  @override
  String get loanApprovedBy => 'Approved by';
  @override
  String get loanDisbursedOn => 'Disbursed on';
  @override
  String get loanToastInReview => 'Status: in review.';
  @override
  String get loanToastApproved => 'Loan approved.';
  @override
  String get loanToastDisbursed => 'Disbursement recorded.';
  @override
  String get loanToastCancelled => 'Loan cancelled.';
  @override
  String get loanToastRejected => 'Loan rejected.';
  @override
  String get loanToastInstallmentRecorded => 'Installment recorded.';
  @override
  String get paymentToastRejected => 'Payment rejected.';
  @override
  String get paymentToastConfirmed => 'Confirmed.';

  // Messages
  @override
  String get messagesTitle => 'Messages';
  @override
  String get messagesEmpty => 'No messages yet';
  @override
  String get messagesEmptyMessage =>
      'Conversations with your cooperative admin will appear here.';
  @override
  String get threadTitle => 'Conversation';
  @override
  String get threadReply => 'Reply…';
  @override
  String get threadSend => 'Send';

  // Notifications
  @override
  String get notificationsTitle => 'Notifications';
  @override
  String get notificationsEmpty => 'No notifications yet';
  @override
  String get notificationsEmptyMessage =>
      'Updates on applications, payments, and quotas will appear here.';
  @override
  String get notificationsReadAll => 'Mark all as read';

  // Edit Profile
  @override
  String get editProfileTitle => 'Edit Profile & Electricity Tariff';
  @override
  String get editProfileName => 'Full name';
  @override
  String get editProfileBusiness => 'Business name';
  @override
  String get editProfileCity => 'City';
  @override
  String get editProfileTariff => 'Electricity tariff (Rp/kWh)';
  @override
  String get editProfileSave => 'Save';
  @override
  String get editProfileSuccess => 'Profile updated successfully.';

  // Change PIN
  @override
  String get changePinTitle => 'Change PIN';
  @override
  String get changePinCurrentPin => 'Current PIN';
  @override
  String get changePinNewPin => 'New PIN';
  @override
  String get changePinSuccess => 'PIN changed successfully.';

  // About
  @override
  String get aboutTitle => 'About IbuDaya';
  @override
  String get aboutVersion => 'Version';
  @override
  String get aboutClearSample => 'Remove sample data';
  @override
  String get aboutClearSampleConfirmTitle => 'Remove sample data?';
  @override
  String get aboutClearSampleConfirmBody =>
      'Koperasi Energi Melati along with all its members and data will be deleted.';
  @override
  String get aboutClearSampleSuccess => 'Sample data removed successfully.';
  @override
  String get aboutResetDevice => 'Reset all data';
  @override
  String get aboutResetDeviceConfirmTitle => 'Delete all data?';
  @override
  String get aboutResetDeviceConfirmBody =>
      'All accounts, records, and data on this device will be permanently deleted.';
  @override
  String get aboutResetDeviceSuccess => 'Data deleted successfully.';
  @override
  String get aboutTagline => 'Efficient energy, stronger business';
  @override
  String get aboutDescription =>
      "IbuDaya helps women-owned micro-businesses manage their "
      "electricity costs, use the cooperative's Solar Hub, join energy "
      "arisan, and apply for a business loan from their cooperative.";
  @override
  String get aboutNumbersSection => 'Where the numbers come from';
  @override
  String get aboutNumbersBody =>
      '• Bill scans are read on your phone (Google ML Kit), never sent '
      'online. You always check the numbers before saving.\n'
      '• Per-appliance breakdown = watts × hours used × your tariff. '
      'This is an estimate.\n'
      '• The Energy Credit Score uses fixed rules with the 4 factors '
      'shown on the score screen. Not artificial intelligence, not a '
      'bank score.\n'
      '• Loan decisions are made by the cooperative admin.\n'
      '• CO₂ uses an assumption of 0.87 kg per kWh of PLN electricity.';
  @override
  String get aboutDataStorageSection => 'Data storage';
  @override
  String get aboutDataStorageBody =>
      "Right now all data is stored only on this phone. The next "
      "version connects to the cooperative's server so members and "
      "admins can see each other's data from their own phones.";
  @override
  String aboutFooter(String teamName) => 'Made by the $teamName team.';
  @override
  String get inviteCardFirstMember => 'Invite your first member';
  @override
  String get inviteCardTitle => 'Cooperative code';
  @override
  String get inviteCardCopyTooltip => 'Copy code';
  @override
  String inviteCardShareMessage(String coopName, String code) =>
      'Join $coopName on the IbuDaya app. Choose Register → Cooperative '
      'member, then enter code $code.';
  @override
  String get inviteCardCopiedToast => 'Invite message copied.';
  @override
  String get inviteCardCaption =>
      "Members enter this code when they register. Don't share it "
      'outside the cooperative.';
  @override
  String arisanQuotaActionConfirmTitle(String action) => '$action the quota?';
  @override
  String get arisanQuotaUpdatedToast => 'Quota updated.';
  @override
  String get arisanQuotaSentToast => 'Sent.';
  @override
  String get bookingCancelledToast => 'Booking cancelled.';
  @override
  String get bookingRecordedToast => 'Recorded.';
  @override
  String solarBookingComeOnTime(String hubName) =>
      'Come to $hubName as scheduled.';
  @override
  String get bookingCustomApplianceSublabel => 'Custom appliance';
  @override
  String get appliancesMonthlyEstimateLabel => 'Estimated per month';
  @override
  String loginPinForPhone(String phone) => 'Enter the PIN for $phone';

  // Admin Dashboard
  @override
  String get adminDashTitle => 'Dashboard';
  @override
  String get adminMembers => 'Members';
  @override
  String get adminSectionManage => 'Manage cooperative';
  @override
  String get adminPaymentsMenu => 'Confirm arisan payments';
  @override
  String get adminArisanMenu => 'Arisan groups';
  @override
  String get adminHubMenu => 'Solar Hub & slots';
  @override
  String get adminAnnounceMenu => 'Send announcement';
  @override
  String get adminMessagesMenu => 'Messages';
  @override
  String get adminSettingsMenu => 'Cooperative & loan settings';
  @override
  String get adminSettingsSubtitle =>
      'Invite code, ceiling, interest, tenor, quota';
  @override
  String get adminSectionAccount => 'Account';
  @override
  String get adminEditProfile => 'Edit profile';
  @override
  String get adminChangePin => 'Change PIN';

  @override
  String get adminLoansTitle => 'Loan Applications';
  @override
  String get adminLoansEmpty => 'No applications';
  @override
  String get adminLoansEmptyMessage =>
      'Member financing applications will appear here.';

  @override
  String get adminMembersTitle => 'Members';
  @override
  String get adminMembersEmpty => 'No members yet';
  @override
  String get adminMembersEmptyMessage =>
      'Share the invite code so members can register.';
  @override
  String get adminMemberDetailTitle => 'Member Details';
  @override
  String get adminMemberNotFound => 'Member not found';
  @override
  String get adminMemberSendMessage => 'Send message';
  @override
  String get adminMemberElectricityLast3Months => 'Electricity, last 3 months';
  @override
  String get adminMemberLoansSection => 'Loans';
  @override
  String get adminMemberNoLoans => 'Never submitted an application.';
  @override
  String get adminMemberNoScore => 'Score cannot be calculated yet';
  @override
  String get adminMemberScorePendingShort => 'No score';
  @override
  String get adminMemberArisanSection => 'Arisan';

  @override
  String get adminPaymentsTitle => 'Payment Confirmation';
  @override
  String get adminPaymentsEmpty => 'No pending payments';
  @override
  String get adminPaymentsApprove => 'Confirm';
  @override
  String get adminPaymentsReject => 'Reject';

  @override
  String get adminArisanTitle => 'Arisan Groups';
  @override
  String get adminArisanNewGroup => 'Create new group';
  @override
  String get adminArisanGroupName => 'Group name';
  @override
  String get adminArisanDues => 'Dues per cycle';
  @override
  String get adminArisanCycle => 'Cycle length';
  @override
  String get arisanAdminCreateGroupButton => 'Create arisan group';
  @override
  String get arisanAdminEmptyTitle => 'No arisan groups yet';
  @override
  String get arisanAdminEmptyMessage =>
      'Create a group, pick its members, and set the turn order.';
  @override
  String get arisanAdminDuesPerMonth => 'Dues per month';
  @override
  String arisanAdminMemberCount(int n) => '$n people';
  @override
  String get arisanAdminStartMonth => 'Start';
  @override
  String get arisanAdminPaidThisMonth => 'Paid this month';
  @override
  String arisanAdminDisbursedTo(String name, String amount) =>
      'Already disbursed to $name ($amount).';
  @override
  String arisanAdminRecordPayoutTo(String name) => 'Record payout to $name';
  @override
  String get arisanAdminRecordPayoutConfirmTitle => 'Record payout?';
  @override
  String arisanAdminRecordPayoutConfirmMessage(
    String amount,
    String name,
    String month,
  ) => '$amount handed to $name for $month.';
  @override
  String arisanAdminRecordPayoutWarning(int paid, int total) =>
      '\n\nNote: only $paid of $total members have paid so far.';
  @override
  String get arisanAdminRecordPayoutAction => 'Record';
  @override
  String get arisanAdminPayoutRecordedToast => 'Payout recorded.';
  @override
  String get arisanAdminTurnOrderSection => 'Turn order';
  @override
  String get arisanAdminCreateTitle => 'Create Arisan Group';
  @override
  String arisanAdminCreateButton(int n) => 'Create group ($n members)';
  @override
  String get arisanAdminGroupNameRequired => 'Enter the group name.';
  @override
  String get arisanAdminMinAmount => 'Minimum Rp 1,000.';
  @override
  String get arisanAdminStartMonthLabel => 'Start month';
  @override
  String get arisanAdminPickMembersTitle => 'Pick members in turn order';
  @override
  String get arisanAdminPickMembersHint =>
      'Tap the member who receives first, then second, and so on.';
  @override
  String get arisanAdminNeedMoreMembers =>
      'Needs at least 2 registered members. Share the cooperative code first.';
  @override
  String get arisanAdminGroupCreatedToast =>
      'Arisan group created. Members have been notified.';
  @override
  String get arisanDrawButton => 'Draw Lottery';
  @override
  String get arisanDrawDialogTitle => 'Drawing Turn Order';
  @override
  String get arisanDrawHint =>
      "Each member is drawn only once — once she's drawn, she's out of the "
      'pool until everyone else has had a turn.';
  @override
  String get arisanDrawInProgress => 'Drawing…';
  @override
  String arisanDrawSlot(int turn, String name) => 'Turn #$turn: $name';
  @override
  String get arisanDrawRedo => 'Redraw';
  @override
  String get arisanDrawConfirm => 'Use This Order';
  @override
  String get arisanDrawCancel => 'Cancel';

  @override
  String get adminHubTitle => 'Solar Hub & Slots';
  @override
  String get adminHubCapacity => 'Daily capacity (kWh)';
  @override
  String get adminHubSlots => 'Time slots';
  @override
  String get hubNotFound => 'Solar Hub not found';
  @override
  String get hubFieldName => 'Hub name';
  @override
  String get hubFieldNameRequired => 'Enter the hub name.';
  @override
  String get hubFieldLocation => 'Location';
  @override
  String get hubFieldCapacity => 'Daily energy capacity';
  @override
  String get hubFieldCapacityHelper => 'Enter 0 to pause bookings temporarily.';
  @override
  String get hubFieldCapacityRequired => 'Enter the capacity.';
  @override
  String get hubCapacityUnknownTitle => "Don't know the capacity yet?";
  @override
  String get hubCapacityHint => 'Installed panel power';
  @override
  String hubCapacitySuggestion(String kwh) =>
      '≈ $kwh per day (kWp × 4 sun hours × 80%)';
  @override
  String get hubCapacityUse => 'Use';
  @override
  String get hubFieldWeatherCode => 'BMKG weather region code';
  @override
  String get hubFieldWeatherCodeHelper =>
      'Optional. A kelurahan-level region code from data.bmkg.go.id, e.g. '
      '16.71.05.1001 — used to show the best production hours based on '
      'real weather on the member Solar Hub screen. Leave it blank if you '
      "don't know the code yet; the panel stays hidden until it's filled in.";
  @override
  String get hubFieldQuota => 'Default monthly quota per member';
  @override
  String get hubFieldQuotaHelper =>
      "Used when a member doesn't have her own capacity allocation. Set a "
      'per-member allocation on her member detail page.';
  @override
  String get hubFieldQuotaRequired => 'Enter the quota.';
  @override
  String get hubSlotsSection => 'Time slots';
  @override
  String get hubAddSlotDialogTitle => 'Add slot';
  @override
  String get hubSlotStart => 'Start';
  @override
  String get hubSlotEnd => 'End';
  @override
  String get hubSlotAddedToast => 'Slot added.';
  @override
  String get hubSlotDeleteTooltip => 'Delete slot';
  @override
  String hubSlotDeleteConfirmTitle(String label) => 'Delete slot $label?';
  @override
  String get hubSlotDeleteConfirmMessage =>
      'A slot that still has bookings cannot be deleted.';
  @override
  String get hubSlotDeletedToast => 'Slot deleted.';
  @override
  String hubSlotHours(int hours) => '$hours hours';
  @override
  String get hubBookingsToConfirmSection => "Today's unconfirmed bookings";
  @override
  String get hubBookingMarkUsed => 'Used';
  @override
  String get hubBookingMarkedUsedToast => 'Marked as used.';
  @override
  String get hubConnectionRequestsSection =>
      'Connection requests awaiting verification';
  @override
  String get hubConnectionApprove => 'Approve';
  @override
  String adminSummarySubtitle(int active, int total, int ready, int trades) =>
      '$active/$total active · $ready loan-ready · $trades quota trades';
  @override
  String get adminSummaryActive => 'Active members';
  @override
  String get adminSummaryLoanReady => 'Loan-ready';
  @override
  String get adminSummaryTrades => 'Quota trades';
  @override
  String get adminSummaryTradedKwh => 'Quota moved';
  @override
  String get adminSummaryUtilization => 'Hub utilisation';
  @override
  String get adminSummaryUtilizationHint =>
      'Share of members\' monthly quota used this month.';
  @override
  String get adminSummaryRepayment => 'Installments on time';
  @override
  String get adminSummaryRepaymentNone =>
      'No installments have fallen due yet.';
  @override
  String adminSummaryRepaymentDetail(int ok, int due) =>
      '$ok of $due installments that fell due';
  @override
  String get loanReadyBadge => 'Loan-ready';
  @override
  String get adminKpiTitle => 'Cooperative summary';
  @override
  String get adminKpiNote =>
      'The proposal\'s targets (95% on-time repayment, 37.5% lower energy cost) are projections. Only the figures above are measured in the app.';
  @override
  String get creditReportTitle => 'Energy Credit Report';
  @override
  String get creditReportOpen => 'View Energy Credit Report';
  @override
  String get creditReportEmpty =>
      'The report is available once your score can be calculated (3 recorded months).';
  @override
  String get creditReportIntro =>
      'A summary of your Solar Hub data. The score uses fixed, inspectable rules, not an AI model, and is not a loan decision.';
  @override
  String get creditReportCopy => 'Copy report';
  @override
  String get creditReportConsentTitle => 'Share this report?';
  @override
  String get creditReportConsentBody =>
      'The report contains your score and energy usage summary. Copy it only if you agree to share it with a financial institution of your choice.';
  @override
  String get creditReportCopied =>
      'Report copied. Paste it into a message to the institution of your choice.';
  @override
  String get creditReportMonths => 'Solar Hub usage per month';
  @override
  String get creditReportActivity => 'Last 8 weeks';
  @override
  String creditReportSessions(int n, String kwh) => '$n sessions · $kwh';
  @override
  String get creditReportAppliances => 'Registered appliances';
  @override
  String get creditReportQuota => 'Quota sharing';
  @override
  String creditReportQuotaValue(int given, int received) =>
      'shared $given · received $received';
  @override
  String get creditReportDues => 'Confirmed arisan dues';
  @override
  String get creditReportInstallments => 'Installments on time';
  @override
  String creditReportInstallmentsValue(int ok, int due) => '$ok of $due due';
  @override
  String get creditReportInstallmentsNone => 'none due yet';
  @override
  String get quotaShareToAny => 'To anyone';
  @override
  String get quotaShareToMember => 'To a specific member';
  @override
  String get quotaShareToAnyHint =>
      'Shown in the quota market. The first member to take it receives it right away.';
  @override
  String get quotaShareToMemberHint =>
      'Sent only to the member you pick. She can accept or decline.';
  @override
  String get quotaPickMember => 'Choose the receiving member';
  @override
  String get quotaPickMemberRequired => 'Choose a receiving member first.';
  @override
  String get quotaGiftIncomingTitle => 'Quota for you';
  @override
  String quotaGiftFrom(String name, String kwh) =>
      '$name wants to share $kwh with you';
  @override
  String get quotaGiftAccept => 'Accept';
  @override
  String get quotaGiftDecline => 'Decline';
  @override
  String get quotaGiftAcceptedToast => 'Quota accepted and recorded.';
  @override
  String get quotaGiftDeclinedToast => 'Quota declined.';
  @override
  String quotaGiftWaiting(String name) => 'For $name · waiting for an answer';
  @override
  String quotaGiftSentMessage(String name) =>
      'Sent to $name. The quota moves once she accepts.';
  @override
  String get quotaMatchTitle => 'A good match for you';
  @override
  String get quotaMatchRule =>
      'Order: best-fitting amount first, then whoever has waited longest.';
  @override
  String quotaMatchShareCovers(String kwh) =>
      'Offers $kwh — covers what you need';
  @override
  String quotaMatchShareShort(String kwh, String missing) =>
      'Offers $kwh — $missing short of what you need';
  @override
  String quotaMatchNeedFits(String kwh) => 'Needs $kwh — you can cover it';
  @override
  String get quotaTradedToast => 'Trade recorded.';
  @override
  String quotaTradeConfirm(String kwh, String name) =>
      '$kwh with $name. The quota moves right away and is recorded.';
  @override
  String get quotaLedgerTitle => 'Quota ledger';
  @override
  String quotaLedgerGave(String name) => 'Shared with $name';
  @override
  String quotaLedgerGot(String name) => 'Received from $name';
  @override
  String get quotaLedgerEmpty => 'No quota trades yet.';
  @override
  String get quotaLedgerNote =>
      'A trade only records an agreement between members. Power still flows through each member\'s limiter.';
  @override
  String get hubConnectSending => 'Sending request…';
  @override
  String get hubConnectScanAgain => 'Scan again';
  @override
  String get hubConnectApprovedTitle => 'Approved by admin';
  @override
  String get hubConnectApprovedMessage =>
      'The admin approved. The hub is supplying power within your capacity.';
  @override
  String get hubConnectRejectedTitle => 'Rejected by admin';
  @override
  String get hubConnectRejectedMessage =>
      'Your request wasn\'t approved. Contact your cooperative admin if you have questions.';
  @override
  String get hubConnectDoneTitle => 'Verified';
  @override
  String get hubConnectDoneMessage =>
      'The hub is supplying power within your capacity. Usage was recorded automatically in Electricity Records.';
  @override
  String get hubConnectBrowse => 'Browse the app';
  @override
  String get adminRequestsTitle => 'Hub Usage Verification';
  @override
  String get adminRequestsEmpty => 'No requests waiting.';
  @override
  String get adminRequestsIntro =>
      'Members who scan the hub QR appear here. Approve only if they are really using the hub.';
  @override
  String get adminRequestsCardTitle => 'Hub usage verification';
  @override
  String get hubConnectionReject => 'Reject';
  @override
  String get hubConnectionApprovedToast => 'Request approved.';
  @override
  String get hubConnectionRejectedToast => 'Request rejected.';

  @override
  String get hubConnectCta => 'Scan QR Now';
  @override
  String get hubConnectTitle => 'Connect to Solar Hub';
  @override
  String get hubConnectInstruction =>
      'Point your camera at the QR code on your hub connection.';
  @override
  String get hubConnectWrongCode =>
      'This isn\'t your cooperative\'s Solar Hub QR.';
  @override
  String get hubConnectOffHours =>
      'The Solar Hub is currently outside its operating hours.';
  @override
  String get hubConnectSentTitle => 'Waiting for admin verification';
  @override
  String get hubConnectSentMessage =>
      'Your request has been sent. The admin will review and approve it.';

  @override
  String get adminMemberHubSection => 'Solar Hub Connection';
  @override
  String get adminMemberHubAllocation => 'Hub capacity allocation';
  @override
  String get adminMemberHubAllocationHint => 'Leave blank to use the default';
  @override
  String get adminMemberHubAllocationHelper =>
      "This member's own monthly capacity, from her installed limiter's "
      "rating. Leave blank to use the cooperative's default quota.";

  @override
  String get adminAnnounceTitle => 'Send Announcement';
  @override
  String get adminAnnounceMessage => 'Announcement message';
  @override
  String get adminAnnounceSend => 'Send to all members';
  @override
  String get adminAnnounceSent => 'Announcement sent successfully.';
  @override
  String adminAnnounceSendCount(int count) => 'Send to $count members';
  @override
  String get adminAnnounceConfirmTitle => 'Send announcement?';
  @override
  String get adminAnnounceConfirmMessage =>
      'All members will get a notification.';
  @override
  String get adminAnnounceConfirmSend => 'Send';
  @override
  String get adminAnnounceHint =>
      'Example: The Solar Hub is closed Friday for panel maintenance.';
  @override
  String get adminAnnounceHelper =>
      'Keep it short and clear. Mention the date and time if needed.';
  @override
  String get adminAnnouncePreviousSection => 'Previous announcements';

  @override
  String get adminSettingsTitle => 'Cooperative & Loan Settings';
  @override
  String get adminSettingsInviteCode => 'Invite code';
  @override
  String get adminSettingsLoanCeiling => 'Maximum ceiling (Rp)';
  @override
  String get adminSettingsLoanMin => 'Minimum score to apply';
  @override
  String get adminSettingsTenor => 'Maximum tenor (months)';
  @override
  String get adminSettingsInterest => 'Monthly interest (%)';
  @override
  String get adminSettingsSave => 'Save settings';
  @override
  String get adminSettingsSaved => 'Settings saved successfully.';
  @override
  String get coopSettingsNewCodeButton => 'Generate new code';
  @override
  String get coopSettingsNewCodeConfirmTitle => 'Generate a new invite code?';
  @override
  String coopSettingsNewCodeConfirmMessage(String oldCode) =>
      'The old code $oldCode will stop working. Members who already '
      'joined are not affected.';
  @override
  String get coopSettingsNewCodeToast => 'Invite code changed.';
  @override
  String get coopSettingsNameLabel => 'Cooperative name';
  @override
  String get coopSettingsNameRequired => 'Enter the cooperative name.';
  @override
  String get coopSettingsArisanSection => 'Arisan dues';
  @override
  String get coopSettingsBankAccountLabel => 'Treasurer account (optional)';
  @override
  String get coopSettingsBankAccountHelper =>
      'Shown to members when they pay dues, e.g. "BCA 1234567890 a/n '
      'Koperasi Energi Melati". Leave it blank if dues are cash-only — '
      "don't fill it in if the account isn't settled yet, so members "
      "don't transfer to the wrong place.";
  @override
  String get coopSettingsLoanPolicySection => 'Loan policy';
  @override
  String get coopSettingsLoanPolicyWarning =>
      "Make sure this policy matches your cooperative's bylaws and "
      'savings-and-loan license. Changes only apply to new applications.';
  @override
  String get coopSettingsCeilingRequired => 'Minimum Rp 500,000.';
  @override
  String coopSettingsCeilingByScore(String bands) =>
      "Each member's ceiling follows her score: $bands.";
  @override
  String get coopSettingsInterestRequired => 'Enter 0 to 5%.';
  @override
  String get coopSettingsTenorRequiredToast => 'Pick at least one tenor.';
  @override
  String get coopSettingsTenorSection => 'Tenor options';

  // ── Extra Localizations ──────────────────────────────────────────────────
  @override
  String monthShort(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][(month - 1).clamp(0, 11)];
  @override
  String monthLong(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][(month - 1).clamp(0, 11)];
  @override
  String dayShort(int weekday) => const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ][(weekday - 1).clamp(0, 6)];
  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get qualifierEstimasi => 'estimate';
  @override
  String get qualifierEstimasiAwal => 'initial estimate';
  @override
  String get qualifierSimulasi => 'simulation';
  @override
  String get qualifierIlustrasi => 'illustration';
  @override
  String get qualifierDataContoh => 'sample data';
  @override
  String get qualifierDataKomunitas => 'community data';
  @override
  String get qualifierDataLangsung => 'live data';

  @override
  String get solarWeatherTitle => 'Best production window today';
  @override
  String solarWeatherReason(int cloudPct, String condition) =>
      'BMKG: $condition, $cloudPct% cloud cover';
  @override
  String get solarWeatherSource => 'Source: BMKG (data.bmkg.go.id)';
  @override
  String solarWeatherScore(int score, int tempC) =>
      'Production score $score/100 · $tempC°C';
  @override
  String get solarWeatherRainNote => 'BMKG forecasts rain — score reduced.';
  @override
  String get solarBookingBestWeather => 'Best weather hours';
  @override
  String get solarWeatherPassedTitle => 'Today\'s best hours have passed';
  @override
  String get solarWeatherPassedHint => 'Check again tomorrow morning.';
  @override
  String get solarWeatherTomorrowTitle => 'Best production window tomorrow';

  // Solar panel QR scan (demo)

  @override
  String get creditBandPerluPeningkatan => 'Needs Improvement';
  @override
  String get creditBandCukup => 'Fair';
  @override
  String get creditBandBaik => 'Good';
  @override
  String get creditBandBaikSekali => 'Excellent';

  @override
  String get roleAdmin => 'Cooperative Admin';
  @override
  String get roleMember => 'Member';

  @override
  String get appliancePresetOven => 'Oven';
  @override
  String get appliancePresetKulkas => 'Refrigerator';
  @override
  String get appliancePresetMesinJahit => 'Sewing Machine';
  @override
  String get appliancePresetBlender => 'Blender';
  @override
  String get appliancePresetRiceCooker => 'Rice Cooker';
  @override
  String get appliancePresetMixer => 'Mixer';
  @override
  String get appliancePresetSetrika => 'Iron';
  @override
  String get appliancePresetKipasAngin => 'Fan';
  @override
  String get appliancePresetLainnya => 'Other';

  @override
  String obsSpikeTitle(int pct) => 'Usage spike of $pct%';
  @override
  String obsSpikeBodyExtra(String extra) =>
      'About $extra higher than last month.';
  @override
  String get obsSpikeBodyAvg =>
      'This month\'s usage is above previous average.';
  @override
  String obsSavingTitle(int pct) => 'Usage down $pct%';
  @override
  String get obsSavingBody => 'Lower than last month. Keep it up!';
  @override
  String get obsMismatchTitle => 'Appliance data needs checking';
  @override
  String get obsMismatchBody =>
      'Total appliance usage exceeds your electricity record.';
  @override
  String obsTopApplianceTitle(String name) => '$name consumes the most';
  @override
  String obsTopApplianceBody(String cost) =>
      '±$cost/month. Shift usage to Solar Hub hours.';
  @override
  String get obsConfirmBookingTitle => 'Confirm hub usage';
  @override
  String obsConfirmBookingBody(int count) =>
      '$count schedule(s) passed. Mark as used to log savings.';
  @override
  String get obsUseHubTitle => 'Use the Solar Hub this month';
  @override
  String get obsUseHubBody =>
      'No electricity records for this month yet — use the hub so they log automatically.';
  @override
  String get obsNoApplianceTitle => 'Register business appliances';
  @override
  String get obsNoApplianceBody =>
      'So bill usage can be broken down per appliance.';

  @override
  String energyAnalysisUsage(String month) => 'Usage for $month';
  @override
  String get energyAnalysisNoPrev => 'Record next month to see usage changes.';
  @override
  String energyAnalysisUp(int pct, String month, String extra) =>
      'Up $pct% from $month$extra';
  @override
  String energyAnalysisDown(int pct, String month) => 'Down $pct% from $month';
  @override
  String energyAnalysisMoreExpensive(String extra) =>
      ' · about $extra more expensive';
  @override
  String get energyAnalysisSpikeTitle => 'Spike detected';
  @override
  String get energyAnalysisSpikeBody =>
      'This month is over 15% above the 3-month average. Check appliances with increased usage hours.';
  @override
  String get energyAnalysisTrend6Months => '6-Month Trend';
  @override
  String get energyAnalysisBreakdownTitle => 'Appliance Breakdown';
  @override
  String energyAnalysisMismatchBody(String declared, String actual) =>
      'Total appliance usage ($declared) exceeds recorded bill ($actual). Please check wattage or usage hours.';
  @override
  String get energyAnalysisUnregistered => 'Unregistered (lights, etc.)';
  @override
  String get energyAnalysisSavingTipTitle => 'Savings Advice';
  @override
  String energyAnalysisSavingTipBody(String name, String kwh, String cost) =>
      '$name uses about $kwh per month (± $cost). Use it during cooperative Solar Hub hours to reduce PLN bills.';
  @override
  String energyAnalysisFormula(String tariff) =>
      'Calculation method: watts × hours/day × days/week × 30/7 ÷ 1000 = kWh/month, multiplied by your tariff $tariff/kWh. Figures are estimates based on appliances filled in.';

  @override
  String get solarHubCoop => 'Cooperative Solar Hub';
  @override
  String get solarCapacityToday => 'Today\'s energy capacity';
  @override
  String solarCapacityAvailable(String rem, String cap) =>
      'available · $rem of $cap';
  @override
  String get solarBookingScheduleBtn => 'Book Schedule';
  @override
  String get solarQuotaThisMonth => 'Energy quota this month';
  @override
  String solarQuotaRemaining(String rem) => '$rem remaining';
  @override
  String solarQuotaAllocationUsed(String alloc, String booked) =>
      'Allowance $alloc · used $booked';
  @override
  String get solarSwap => 'Swap';
  @override
  String get solarTodaySlots => 'Today\'s slots';
  @override
  String get solarSlotCapacityNote =>
      'Slot capacity is divided based on estimated sunlight (06:00–18:00): afternoon slots get a larger share.';
  @override
  String get solarSlotPassed => 'Passed';
  @override
  String get solarMyScheduleAll => 'All';
  @override
  String get solarNoUpcoming => 'No upcoming schedule yet.';

  @override
  String get loanStatusSubmitted => 'Submitted';
  @override
  String get loanStatusInReview => 'In review';
  @override
  String get loanStatusApproved => 'Approved';
  @override
  String get loanStatusRejected => 'Rejected';
  @override
  String get loanStatusDisbursed => 'Disbursed';
  @override
  String get loanStatusRepaid => 'Repaid';
  @override
  String get loanStatusCancelled => 'Cancelled';
  @override
  String get loanPurposeRawMaterial => 'Raw materials';
  @override
  String get loanPurposeEquipment => 'Production equipment';
  @override
  String get loanPurposeRenovation => 'Business renovation';
  @override
  String get loanPurposeOther => 'Other';

  @override
  String get paymentStatusPending => 'Pending confirmation';
  @override
  String get paymentStatusConfirmed => 'Confirmed';
  @override
  String get paymentStatusRejected => 'Rejected';
  @override
  String get paymentTypeContribution => 'Dues payment';
  @override
  String get paymentTypePayout => 'Turn payout';
  @override
  String get bookingStatusPendingVerification => 'Pending verification';
  @override
  String get bookingStatusBooked => 'Scheduled';
  @override
  String get bookingStatusCompleted => 'Completed';
  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get arisanNotJoinedTitle => 'Not in an arisan group yet';
  @override
  String get arisanNotJoinedMsg =>
      'Arisan groups are created by the coop admin. Ask your admin to add you to a group.';
  @override
  String get arisanSendMessageToAdmin => 'Send message to admin';
  @override
  String get arisanGroupChat => 'Group chat';
  @override
  String get arisanTotalPerMonth => 'Total arisan per month';
  @override
  String get arisanDuesLabel => 'Dues';
  @override
  String get arisanTurnThisMonth => 'This month\'s turn';
  @override
  String get arisanYourTurn => 'Your turn';
  @override
  String arisanDuesMonth(String month) => 'Dues for $month';
  @override
  String arisanStartsMonth(String month) => 'Arisan starts in $month.';
  @override
  String get arisanPrevRejected => 'Previous payment rejected';
  @override
  String get arisanPrevRejectedNote => 'Contact admin for details.';
  @override
  String arisanPayInstruction(String amount) =>
      'Hand in dues of $amount to the treasurer in cash, then tap the button below. Admin will confirm.';
  @override
  String arisanPayInstructionWithBank(String amount, String bankAccount) =>
      'Hand in dues of $amount to the treasurer in cash, or transfer to $bankAccount. Then tap the button below — admin will confirm.';
  @override
  String get arisanPaidBtn => 'I have paid';
  @override
  String get arisanPaidSuccess => 'This month\'s dues are fully paid.';
  @override
  String get arisanPaidPending =>
      'Payment sent, waiting for admin confirmation.';
  @override
  String arisanPayoutInfo(String name, String amount) =>
      'This month\'s arisan payout has been disbursed to $name ($amount).';
  @override
  String get arisanEnergyTrading => 'Energy Arisan';
  @override
  String get arisanEnergyTradingSub =>
      'Share remaining Solar Hub quota with fellow members, or request when needed.';
  @override
  String arisanMembersCount(int count) => 'Members ($count)';
  @override
  String get arisanMyHistory => 'My history';
  @override
  String get arisanPayConfirmTitle => 'Have you handed in the dues?';
  @override
  String arisanPayConfirmMsg(String amount) =>
      'Press "Send" only if $amount has been handed to the treasurer. Admin will check and confirm.';
  @override
  String get arisanYouTag => '(You)';
  @override
  String arisanTurnFormat(int turn, String month) => 'Turn #$turn · $month';
  @override
  String get arisanReceivingThisMonth => ' · receiving this month';
  @override
  String get arisanNotPaidYet => 'Not paid';
  @override
  String get arisanPaidStatus => 'Paid';
  @override
  String get arisanWaitingStatus => 'Waiting';

  @override
  String get scoreNotCalculatedTitle => 'Score cannot be calculated yet';
  @override
  String scoreNotCalculatedMsg(int min) =>
      'Your score is calculated from your own records. With fewer than $min months of data, the figure is not yet reliable.';
  @override
  String scoreRecordsCount(int current, int min) =>
      'Electricity records $current/$min months';
  @override
  String get scoreRecordsEnough => 'Sufficient electricity records';
  @override
  String scoreUseHubMoreMonths(int n) =>
      'Use the Solar Hub for $n more month${n == 1 ? '' : 's'}';
  @override
  String get scoreUseHubMoreMonthsSubtitle =>
      'Your electricity record fills in automatically after each Solar Hub session.';
  @override
  String get scoreInArisan => 'Already in arisan';
  @override
  String get scoreJoinArisan => 'Join cooperative arisan group';
  @override
  String scoreAppliancesDeclaredCount(int count) =>
      '$count appliance${count == 1 ? '' : 's'} registered';
  @override
  String get scoreRegisterAppliance => 'Register business appliances';
  @override
  String get scoreFrom100 => 'out of 100';
  @override
  String get scoreFirstThisMonth => 'Your first score this month.';
  @override
  String scoreSameAsMonth(String month) => 'Same as $month.';
  @override
  String scoreDeltaUpFromMonth(int pts, String month) =>
      'Up $pts point${pts == 1 ? '' : 's'} from $month.';
  @override
  String scoreDeltaDownFromMonth(int pts, String month) =>
      'Down $pts point${pts == 1 ? '' : 's'} from $month.';
  @override
  String loanCeilingTitle(String amount) => 'Your ceiling is $amount';
  @override
  String get loanCannotApply => 'Cannot apply yet';
  @override
  String loanCeilingFromScore(int score, String band) =>
      'From score $score ($band).';
  @override
  String loanCoopPolicy(
    String coop,
    String max,
    String rate,
    String tenors,
    int minScore,
  ) =>
      '$coop policy: maximum $max, $rate monthly interest (flat), $tenors months tenor, minimum score $minScore.';
  @override
  String get loanMySubmissions => 'My submissions';
  @override
  String get loanNoSubmissions => 'No submissions yet.';

  @override
  String get eligibilityNone => 'You can apply up to this ceiling.';
  @override
  String get eligibilityNotEnoughHistory =>
      'Use the Solar Hub for at least 3 months to calculate your score.';
  @override
  String get eligibilityScoreTooLow =>
      'Your score has not met the minimum threshold set by the cooperative.';
  @override
  String get eligibilityActiveLoan =>
      'Complete your active loan before applying again.';
}

// Internal helper — avoids importing SampleSeeder into this file.
abstract final class _SamplePin {
  static const String pin = '1234';
}
