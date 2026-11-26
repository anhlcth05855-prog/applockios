import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let appName = application.localizedDisplayName ?? "Ứng dụng"
        return buildShieldConfig(title: "\(appName) đã bị khóa")
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        let appName = application.localizedDisplayName ?? category.localizedDisplayName ?? "Ứng dụng"
        return buildShieldConfig(title: "\(appName) đã bị khóa")
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let domain = webDomain.domain ?? "Trang web"
        return buildShieldConfig(title: "\(domain) đã bị khóa")
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        let domain = webDomain.domain ?? "Trang web"
        return buildShieldConfig(title: "\(domain) đã bị khóa")
    }
    
    private func buildShieldConfig(title: String) -> ShieldConfiguration {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 44, weight: .semibold)
        let lockIcon = UIImage(systemName: "lock.fill", withConfiguration: iconConfig)?
            .withTintColor(UIColor(red: 0.11, green: 0.44, blue: 0.95, alpha: 1.0), renderingMode: .alwaysOriginal)
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialLight,
            backgroundColor: UIColor.systemBackground,
            icon: lockIcon,
            title: ShieldConfiguration.Label(
                text: title,
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Nhấn \"Mở khóa\" để tiếp tục sử dụng.",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Mở khóa",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.11, green: 0.44, blue: 0.95, alpha: 1.0),
            secondaryButtonLabel: nil
        )
    }
}
