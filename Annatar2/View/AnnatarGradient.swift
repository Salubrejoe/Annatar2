import SwiftUI

/// The Annatar accent gradient. Hardcoded to "tundra" (pink → purple → blue
/// → indigo) for now — when themes return, this becomes a function of the
/// selected palette.
extension AngularGradient {

  static let annatarAccent = AngularGradient(
    stops: [
      .init(color: .pink,   location: 0.0),
      .init(color: .purple, location: 0.2),
      .init(color: .blue,   location: 0.5),
      .init(color: .indigo, location: 0.8),
    ],
    center: .center
  )

  static let annatarStale = AngularGradient(
    colors: [.gray],
    center: .center
  )
}
