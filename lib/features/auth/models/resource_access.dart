enum ResourceType {
  group('GROUP'),
  menu('MENU'),
  page('PAGE'),
  feature('FEATURE'),
  element('ELEMENT');

  const ResourceType(this.apiValue);

  final String apiValue;

  static ResourceType fromApi(String value) {
    final normalized = value.toUpperCase();
    return ResourceType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => ResourceType.menu,
    );
  }
}

class ResourceAccessItem {
  ResourceAccessItem({
    required this.resourceId,
    required this.type,
    required this.code,
    required this.displayName,
    required this.parentId,
    required this.displayOrder,
    required this.accessible,
    required this.allowedActions,
    required this.deniedActions,
  });

  final int resourceId;
  final ResourceType type;
  final String code;
  final String displayName;
  final int? parentId;
  final int displayOrder;
  final bool accessible;
  final List<String> allowedActions;
  final List<String> deniedActions;

  factory ResourceAccessItem.fromJson(Map<String, dynamic> json) {
    return ResourceAccessItem(
      resourceId: (json['resourceId'] as num?)?.toInt() ?? 0,
      type: ResourceType.fromApi(json['type'] as String? ?? 'MENU'),
      code: json['code'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      parentId: (json['parentId'] as num?)?.toInt(),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      accessible: json['accessible'] as bool? ?? false,
      allowedActions: _stringList(json['allowedActions']),
      deniedActions: _stringList(json['deniedActions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resourceId': resourceId,
      'type': type.apiValue,
      'code': code,
      'displayName': displayName,
      'parentId': parentId,
      'displayOrder': displayOrder,
      'accessible': accessible,
      'allowedActions': allowedActions,
      'deniedActions': deniedActions,
    };
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}

class UserResourceAccess {
  UserResourceAccess({
    required this.menus,
    required this.pages,
    required this.features,
    required this.elements,
    required this.deniedResources,
  });

  final List<ResourceAccessItem> menus;
  final List<ResourceAccessItem> pages;
  final List<ResourceAccessItem> features;
  final List<ResourceAccessItem> elements;
  final List<ResourceAccessItem> deniedResources;

  factory UserResourceAccess.fromJson(Map<String, dynamic> json) {
    List<ResourceAccessItem> parseList(String key) {
      final raw = json[key];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(ResourceAccessItem.fromJson)
            .toList();
      }
      return const [];
    }

    return UserResourceAccess(
      menus: parseList('menus'),
      pages: parseList('pages'),
      features: parseList('features'),
      elements: parseList('elements'),
      deniedResources: parseList('deniedResources'),
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> toJsonList(List<ResourceAccessItem> items) {
      return items.map((item) => item.toJson()).toList();
    }

    return {
      'menus': toJsonList(menus),
      'pages': toJsonList(pages),
      'features': toJsonList(features),
      'elements': toJsonList(elements),
      'deniedResources': toJsonList(deniedResources),
    };
  }

  List<MenuNode> buildMenuTree({bool onlyAccessible = true}) {
    final items = onlyAccessible
        ? menus.where((item) => item.accessible).toList()
        : List<ResourceAccessItem>.from(menus);

    items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final Map<int, MenuNode> byId = {
      for (final item in items) item.resourceId: MenuNode(item),
    };
    final List<MenuNode> roots = [];

    for (final item in items) {
      final node = byId[item.resourceId]!;
      final parentId = item.parentId;
      if (parentId != null && byId.containsKey(parentId)) {
        byId[parentId]!.children.add(node);
      } else {
        roots.add(node);
      }
    }

    void sortNodes(List<MenuNode> nodes) {
      nodes.sort((a, b) => a.item.displayOrder.compareTo(b.item.displayOrder));
      for (final node in nodes) {
        if (node.children.isNotEmpty) {
          sortNodes(node.children);
        }
      }
    }

    sortNodes(roots);
    return roots;
  }
}

class MenuNode {
  MenuNode(this.item);

  final ResourceAccessItem item;
  final List<MenuNode> children = [];

  bool get hasChildren => children.isNotEmpty;
}
