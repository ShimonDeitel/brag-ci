import SwiftUI

/// Brag's identity: a "performance review" palette — crisp slate-navy on
/// white with a brass "star achievement" accent. Distinct from every
/// sibling app (no cream/amber-gold like Ledger/Jarful, no teal/mint).
enum BGTheme {
    static let backdrop = Color(red: 0.953, green: 0.957, blue: 0.965)   // cool paper white
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.910, green: 0.918, blue: 0.933)
    static let ink = Color(red: 0.106, green: 0.137, blue: 0.204)        // slate-navy
    static let inkFaded = Color(red: 0.106, green: 0.137, blue: 0.204).opacity(0.55)
    static let rule = Color.black.opacity(0.08)

    static let brass = Color(red: 0.686, green: 0.545, blue: 0.259)      // achievement brass
    static let brassBright = Color(red: 0.804, green: 0.655, blue: 0.322)
    static let impactBlue = Color(red: 0.192, green: 0.435, blue: 0.706) // "impact" tag blue

    static let titleFont = Font.system(.title2, design: .default).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .default).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
