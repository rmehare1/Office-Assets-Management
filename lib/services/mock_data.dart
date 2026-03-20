import '../models/asset.dart';
import '../models/user.dart';

class MockData {
  static final AppUser currentUser = AppUser(
    id: 'u1',
    name: 'Sarah Johnson',
    email: 'sarah.johnson@company.com',
    department: 'Engineering',
    role: 'IT Asset Manager',
    phone: '+1 (555) 123-4567',
    assignedAssets: 3,
    joinDate: DateTime(2022, 3, 15),
  );

  static final List<Asset> assets = [
    Asset(
      id: 'a1',
      name: 'MacBook Pro 16"',
      category: AssetCategory.laptop,
      status: AssetStatus.assigned,
      assignedTo: 'Sarah Johnson',
      serialNumber: 'MBP-2024-001',
      location: 'Floor 3, Desk 12',
      purchaseDate: DateTime(2024, 1, 15),
      purchasePrice: 2499.99,
      notes: 'M3 Pro chip, 36GB RAM, 512GB SSD',
    ),
    Asset(
      id: 'a2',
      name: 'Dell UltraSharp 27"',
      category: AssetCategory.monitor,
      status: AssetStatus.available,
      assignedTo: '',
      serialNumber: 'DU27-2024-042',
      location: 'Storage Room B',
      purchaseDate: DateTime(2024, 3, 20),
      purchasePrice: 619.99,
      notes: '4K USB-C monitor',
    ),
    Asset(
      id: 'a3',
      name: 'iPhone 15 Pro',
      category: AssetCategory.phone,
      status: AssetStatus.assigned,
      assignedTo: 'Mike Chen',
      serialNumber: 'IP15-2024-018',
      location: 'Floor 2, Desk 5',
      purchaseDate: DateTime(2024, 2, 10),
      purchasePrice: 1199.00,
      notes: 'Company phone for on-call rotation',
    ),
    Asset(
      id: 'a4',
      name: 'Herman Miller Aeron',
      category: AssetCategory.furniture,
      status: AssetStatus.assigned,
      assignedTo: 'Sarah Johnson',
      serialNumber: 'HMA-2023-067',
      location: 'Floor 3, Desk 12',
      purchaseDate: DateTime(2023, 8, 5),
      purchasePrice: 1395.00,
      notes: 'Size B, fully loaded',
    ),
    Asset(
      id: 'a5',
      name: 'ThinkPad X1 Carbon',
      category: AssetCategory.laptop,
      status: AssetStatus.maintenance,
      assignedTo: 'Alex Rivera',
      serialNumber: 'TPX1-2023-033',
      location: 'IT Repair Center',
      purchaseDate: DateTime(2023, 6, 12),
      purchasePrice: 1849.00,
      notes: 'Battery replacement in progress',
    ),
    Asset(
      id: 'a6',
      name: 'Sony WH-1000XM5',
      category: AssetCategory.accessory,
      status: AssetStatus.assigned,
      assignedTo: 'Sarah Johnson',
      serialNumber: 'SNY-2024-091',
      location: 'Floor 3, Desk 12',
      purchaseDate: DateTime(2024, 4, 1),
      purchasePrice: 349.99,
      notes: 'Noise-canceling headphones',
    ),
    Asset(
      id: 'a7',
      name: 'LG 34" Ultrawide',
      category: AssetCategory.monitor,
      status: AssetStatus.retired,
      assignedTo: '',
      serialNumber: 'LG34-2021-012',
      location: 'Disposal Queue',
      purchaseDate: DateTime(2021, 11, 30),
      purchasePrice: 799.99,
      notes: 'Panel defect, scheduled for recycling',
    ),
    Asset(
      id: 'a8',
      name: 'Standing Desk Frame',
      category: AssetCategory.furniture,
      status: AssetStatus.available,
      assignedTo: '',
      serialNumber: 'SDK-2024-005',
      location: 'Storage Room A',
      purchaseDate: DateTime(2024, 5, 20),
      purchasePrice: 549.00,
      notes: 'Electric sit-stand frame, fits 48-72" tops',
    ),
    Asset(
      id: 'a9',
      name: 'iPad Pro 12.9"',
      category: AssetCategory.other,
      status: AssetStatus.assigned,
      assignedTo: 'Emma Wilson',
      serialNumber: 'IPD-2024-007',
      location: 'Floor 1, Meeting Room C',
      purchaseDate: DateTime(2024, 3, 10),
      purchasePrice: 1099.00,
      notes: 'Used for presentations and design reviews',
    ),
    Asset(
      id: 'a10',
      name: 'Logitech MX Master 3S',
      category: AssetCategory.accessory,
      status: AssetStatus.available,
      assignedTo: '',
      serialNumber: 'LMX-2024-028',
      location: 'Storage Room B',
      purchaseDate: DateTime(2024, 6, 1),
      purchasePrice: 99.99,
    ),
  ];

  static int get totalAssets => assets.length;
  static int get availableAssets =>
      assets.where((a) => a.status == AssetStatus.available).length;
  static int get assignedAssets =>
      assets.where((a) => a.status == AssetStatus.assigned).length;
  static int get maintenanceAssets =>
      assets.where((a) => a.status == AssetStatus.maintenance).length;

  static Map<AssetCategory, int> get categoryBreakdown {
    final map = <AssetCategory, int>{};
    for (final asset in assets) {
      map[asset.category] = (map[asset.category] ?? 0) + 1;
    }
    return map;
  }
}
