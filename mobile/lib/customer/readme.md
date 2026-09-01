# Customer Discovery & Home UI Module

This module contains customer-facing service discovery components and screens.

## Structure
- `models/service_item.dart`: Data model conforming to `docs/api-contract.md` (`service_id`, `name`, `category`, `description`, `base_price_amount`, `image_url`) and mock fixtures (`ServiceItem.mockServices`).
- `widgets/service_card.dart`: Reusable card component for rendering a service listing with image placeholder, category badge, and formatted Rupee price.
- `screens/customer_home_screen.dart`: Customer home screen with location bar, search filter, category chip filter, and reactive service list.
- `screens/service_detail_screen.dart`: Detailed service overview with feature highlights, itemized price breakdown, and "Proceed to Book" action.

