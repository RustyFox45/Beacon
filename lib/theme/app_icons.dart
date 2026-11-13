import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class AppIcons {
  // Navigation & structural
  static Widget home({double size = 24, Color? color}) =>
      _svg('assets/icons/home-icon.svg', size, color);

  static Widget group({double size = 24, Color? color}) =>
      _svg('assets/icons/group-icon.svg', size, color);

  static Widget groupAdd({double size = 24, Color? color}) =>
      _svg('assets/icons/group-add-icon.svg', size, color);

  static Widget profile({double size = 24, Color? color}) =>
      _svg('assets/icons/profile-icon.svg', size, color);

  static Widget signOut({double size = 24, Color? color}) =>
      _svg('assets/icons/sign-out-icon.svg', size, color);

  static Widget menu({double size = 24, Color? color}) =>
      _svg('assets/icons/list-icon.svg', size, color);

  // Actions
  static Widget add({double size = 24, Color? color}) =>
      _svg('assets/icons/plus-icon.svg', size, color);

  static Widget edit({double size = 24, Color? color}) =>
      _svg('assets/icons/edit-icon.svg', size, color);

  static Widget delete({double size = 24, Color? color}) =>
      _svg('assets/icons/delete-icon.svg', size, color);

  static Widget close({double size = 24, Color? color}) =>
      _svg('assets/icons/close-icon.svg', size, color);

  static Widget copy({double size = 24, Color? color}) =>
      _svg('assets/icons/copy-icon.svg', size, color);

  static Widget send({double size = 24, Color? color}) =>
      _svg('assets/icons/send-icon.svg', size, color);

  static Widget search({double size = 24, Color? color}) =>
      _svg('assets/icons/search-icon.svg', size, color);

  // View controls
  static Widget filter({double size = 24, Color? color}) =>
      _svg('assets/icons/filter-icon.svg', size, color);

  static Widget sort({double size = 24, Color? color}) =>
      _svg('assets/icons/sort-icon.svg', size, color);

  static Widget gridView({double size = 24, Color? color}) =>
      _svg('assets/icons/widgets-icon.svg', size, color);

  static Widget viewList({double size = 24, Color? color}) =>
      _svg('assets/icons/view-list-icon.svg', size, color);

  static Widget moreVert({double size = 24, Color? color}) =>
      _svg('assets/icons/more-vert-icon.svg', size, color);

  // Chevrons
  static Widget chevronRight({double size = 24, Color? color}) =>
      _svg('assets/icons/chevron-right-icon.svg', size, color);

  static Widget chevronDown({double size = 24, Color? color}) =>
      _svg('assets/icons/chevron-down-icon.svg', size, color);

  static Widget chevronUp({double size = 24, Color? color}) =>
      _svg('assets/icons/chevron-up-icon.svg', size, color);

  // Status & feedback
  static Widget checkCircle({double size = 24, Color? color}) =>
      _svg('assets/icons/check-circle-icon.svg', size, color);

  static Widget error({double size = 24, Color? color}) =>
      _svg('assets/icons/error-icon.svg', size, color);

  static Widget help({double size = 24, Color? color}) =>
      _svg('assets/icons/help-icon.svg', size, color);

  // Auth
  static Widget visibility({double size = 24, Color? color}) =>
      _svg('assets/icons/visibility-icon.svg', size, color);

  static Widget visibilityOff({double size = 24, Color? color}) =>
      _svg('assets/icons/visibility-off-icon.svg', size, color);

  // Content & data
  static Widget calendar({double size = 24, Color? color}) =>
      _svg('assets/icons/calendar-icon.svg', size, color);

  static Widget link({double size = 24, Color? color}) =>
      _svg('assets/icons/link-icon.svg', size, color);

  static Widget music({double size = 24, Color? color}) =>
      _svg('assets/icons/music-icon.svg', size, color);

  static Widget textFields({double size = 24, Color? color}) =>
      _svg('assets/icons/text-fields-icon.svg', size, color);

  // Settings & security
  static Widget privacy({double size = 24, Color? color}) =>
      _svg('assets/icons/privacy-icon.svg', size, color);

  static Widget key({double size = 24, Color? color}) =>
      _svg('assets/icons/key-icon.svg', size, color);

  static Widget _svg(String path, double size, Color? color) =>
      SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
      );
}
