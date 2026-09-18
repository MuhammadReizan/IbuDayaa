/// Route paths. Lives in core (not app/) because notifications store the path
/// to open, and repositories write those notifications.
abstract final class Paths {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const registerMember = '/register/member';
  static const registerAdmin = '/register/admin';

  // Member shell.
  static const memberHome = '/m/home';
  static const memberSolar = '/m/solar';
  static const memberMessages = '/m/messages';
  static const memberProfile = '/m/profile';
  static const memberRecords = '/m/records';

  // Member flows.
  static const energy = '/energy';
  static const energyAnalysis = '/energy/analysis';
  static const appliances = '/appliances';
  static const applianceEdit = '/appliances/edit';
  static const roof = '/roof';
  static const hubConnect = '/solar/hub-connect';
  static const booking = '/booking';
  static const bookings = '/bookings';
  static const arisan = '/arisan';
  static const quota = '/quota';
  static const quotaNew = '/quota/new';
  static const score = '/score';
  static const creditReport = '/score/report';
  static const loanApply = '/loan/apply';
  static const loans = '/loans';
  static String loan(String id) => '/loans/$id';

  // Shared.
  static String thread(String id) => '/thread/$id';
  static const notifications = '/notifications';
  static const profileEdit = '/profile/edit';
  static const changePin = '/profile/pin';
  static const about = '/about';
  static const language = '/language';

  // Admin shell.
  static const adminHome = '/a/home';
  static const adminLoans = '/a/loans';
  static const adminMembers = '/a/members';
  static const adminMore = '/a/more';

  // Admin flows.
  static String adminLoan(String id) => '/a/loans/$id';
  static String adminMember(String id) => '/a/members/$id';
  static const adminPayments = '/a/payments';
  static const adminArisan = '/a/arisan';
  static const adminArisanNew = '/a/arisan/new';
  static const adminHub = '/a/hub';
  static const adminSummary = '/a/summary';
  static const adminHubRequests = '/a/hub/requests';
  static const adminAnnounce = '/a/announce';
  static const adminSettings = '/a/settings';
  static const adminMessages = '/a/messages';
}
