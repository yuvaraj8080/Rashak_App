import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../features/personalization/controllers/user_controller.dart';
import '../../../utils/Storage/hive_storage.dart';
import '../../../utils/constants/colors.dart';

class TUserProfileTile extends StatelessWidget {
  const TUserProfileTile({
    Key? key,
    required this.onPressed,
  }) : super(key: key);
  final VoidCallback onPressed;


  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>(); // Ensure the controller is found
    return Obx(() {
      final user = controller.user.value; // Access the observable user

      return ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(
            user.profilePicture.isNotEmpty
                ? user.profilePicture
                : "https://www.pngall.com/wp-content/uploads/5/User-Profile-PNG-High-Quality-Image.png",
          ),
        ),
        title: Text(
          user.fullName.isNotEmpty ? user.fullName : 'No Name',
          style: Theme.of(context).textTheme.headlineSmall!.apply(color: TColors.white),
        ),
        subtitle: Text(
          user.email.isNotEmpty ? user.email : 'No Email',
          style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.white),
        ),
        trailing: Card(
          color: Colors.white,
          child: IconButton(
            onPressed: onPressed,
            icon: const Icon(Iconsax.edit, color: Colors.blue, size: 20),
          ),
        ),
      );
    });
  }
}