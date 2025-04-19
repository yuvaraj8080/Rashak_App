import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package
import '../../../../common/widgets.Login_Signup/appBar/appbar.dart';
import '../../../../common/widgets.Login_Signup/custom_shapes/curved_edges.dart/primary_header_controller.dart';
import '../../../../common/widgets.Login_Signup/list_Tile/setting_menu_tile.dart';
import '../../../../common/widgets.Login_Signup/list_Tile/user_profile.dart';
import '../../../../common/widgets.Login_Signup/texts/section_heading.dart';
import '../../../../data/repositories/authentication/authentication-repository.dart';
import '../../../../utils/Storage/hive_storage.dart';
import '../../../../utils/constants/colors.dart';
import '../../../SOS Help Screen/Google_Map/controller/LiveLocationController.dart';
import '../../controllers/user_controller.dart';
import '../profile/profile.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.put(UserController());
    final LiveLocationController livelocationController = Get.put(
        LiveLocationController());
    final storage = THiveStorage.instance();

    // Fetch the initial value from Hive
    bool initialShakeMode = storage.readData<bool>('shakeMode') ?? false;
    livelocationController.isShakeModeEnabled.value = initialShakeMode;

    userController.fetchUserRecord();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [

          ///-------HEADER--------
          TPrimaryHeaderContainer(
            child: Column(children: [
              TAppBar(
                title: Text("Account",
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineMedium!
                        .apply(color: TColors.white)),
              ),

              ///------USER PROFILE CARD-------
              TUserProfileTile(
                  onPressed: () => Get.to(() => const ProfileScreen())),
              const SizedBox(height: 20)
            ]),
          ),

          ///-------PROFILE BODY ---------
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              //// APP SETTING
              const SizedBox(height: 4),
              const TSectionHeading(
                  title: "App Setting", showActionButton: false),
              const SizedBox(height: 4),


              /// SWITCH BUTTON FOR SHAKE MODE
              TSettingMenuTile(
                icon: Iconsax.mobile,
                title: "Mobile Shake",
                subTitle: "Enable Shake features background services",
                trailing: Obx(
                      () =>
                      Switch(
                        value: livelocationController.isShakeModeEnabled.value,
                        onChanged: (value) {
                          // Update the value in the controller
                          livelocationController.isShakeModeEnabled.value =
                              value;

                          // Save the value to Hive
                          storage.saveData<bool>('shakeMode', value);
                        },
                      ),
                ),
              ),

              TSettingMenuTile(
                onTap: () {
                  // Launch the Privacy Policy URL
                  launchURL('https://nirajchalke.github.io/NirajChalke.github.io-PrivacyPolicy/');
                },
                icon: Icons.policy,
                title: "Privacy Policy",
                subTitle: "About the Shield App",
              ),

              // ---HELPLINE SERVICES----
              TSettingMenuTile(
                onTap: () {
                  // Launch the Help Center URL
                  launchURL(
                      'mailto:yuvaraj@reidiusinfra.com'); // Open email client
                },
                icon: Icons.headset_mic,
                title: "Help Center",
                subTitle: "yuvaraj@reidiusinfra.com",
              ),

              ///--------LOGOUT BUTTON---------
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => AuthenticationRepository.instance.logout(),
                  child: const Text("Logout"),
                ),
              ),
            ]),
          )
        ]),
      ),
    );
  }

  // Function to launch a URL
  void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}