import AppIntents

#if canImport(UIKit)
import Contacts
#endif

struct GetUserDetails: AppIntent, CustomIntentMigratedAppIntent {
	static let intentClassName = "GetUserDetailsIntent"

	static let title: LocalizedStringResource = "Get User Details"

	static let description = IntentDescription(
"""
Returns details about the current user.

For example, username, name, language, idle time, etc.
""",
		categoryName: "Device"
	)

	@Parameter(title: "Type", default: .name)
	var type: UserDetailsTypeAppEnum

	static var parameterSummary: some ParameterSummary {
		Summary("Get the current user's \(\.$type)")
	}

	func perform() async throws -> some IntentResult & ReturnsValue<String> {
		#if canImport(AppKit)
		let name = User.name
		let nameString = User.nameString
		#else
		let name = CNContactStore().meContactPerson() ?? User.name
		let nameString = name?.formatted()
		#endif

		let result: String? = {
			switch type {
			case .username:
				#if canImport(AppKit)
				return User.username
				#else
				return nil
				#endif
			case .name:
				return nameString
			case .givenName:
				return name?.givenName
			case .familyName:
				return name?.familyName
			case .initials:
				return name?.formatted(.name(style: .abbreviated))
			case .shell:
				return User.shell
			case .languageCode:
				return User.languageCode.identifier
			case .idleTime:
				#if canImport(AppKit)
				return Int(User.idleTime).formatted()
				#else
				return nil
				#endif
			}
		}()

		return .result(value: result ?? "")
	}
}

enum UserDetailsTypeAppEnum: String, AppEnum {
	case username
	case name
	case givenName
	case familyName
	case initials
	case shell
	case languageCode
	case idleTime

	static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "User Details Type")

	static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
		.username: "Username (macOS-only)",
		.name: "Name",
		.givenName: "Given Name",
		.familyName: "Family Name",
		.initials: "Initials",
		.shell: "Shell",
		.languageCode: "Language Code",
		.idleTime: "Idle Time in Seconds (macOS-only)"
	]
}
