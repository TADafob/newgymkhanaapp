// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';

class CommonTopContainer extends StatelessWidget {
  final String title;
  final String Image_url;
  final double? titleposition;
  final bool? isProfile;
  const CommonTopContainer({
    super.key,
    required this.title,
    required this.Image_url,
    this.titleposition,
    this.isProfile,
  });

  @override
  Widget build(BuildContext context) {
    final currentuserId = FirebaseAuth.instance.currentUser!.uid;
    return isProfile == true
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            height: 200,
            width: double.maxFinite,
            decoration: BoxDecoration(
                color: AppKolors.primary,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60))),
            child: Column(
              children: [
                // Stack(
                //   children: [
                //     Positioned(
                //       child: Divider(
                //         height: 80,
                //         indent: 10,
                //       )),
                //     Positioned(
                //     top: 33,
                //     child:
                //     Container(
                //       height: 13,
                //       width: 13,
                //       decoration: BoxDecoration(
                //         shape: BoxShape.circle,
                //         color: AppKolors.blackness,
                //         boxShadow: [
                //           BoxShadow(
                //             color: Colors.black.withValues(alpha: 0.4), // Shadow color with opacity
                //             spreadRadius: 2, // Spread radius for the shadow
                //             blurRadius: 4,  // Blur radius for the shadow
                //             offset: Offset(0, 3), // Offset the shadow (horizontal, vertical)
                //           ),
                //         ]
                //       ),
                //     )),
                //       Positioned(
                //       left: 25,
                //       child: Container(
                //         height: 80,
                //         width: 80,
                //         decoration: BoxDecoration(
                //           color: AppKolors.accent,
                //           shape: BoxShape.circle,
                //         ),
                //         child: Align(
                //           alignment: Alignment.center,
                //           child: Image.asset(
                //             Image_url,
                //             fit: BoxFit.scaleDown,  // Scale down the image to fit within the container
                //             height: 60,  // Adjust the image size to make it smaller
                //             width: 60,   // Adjust the image size to make it smaller
                //           ),
                //         ),)),

                //     Positioned(
                //       top: 45,
                //       left: titleposition,
                //       child:
                //         Text(title, style: AppFonts.headline1,)),
                //   ],
                // ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users_members')
                      .doc(currentuserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.hasError) {
                      return Center(child: Text('Error loading user data'));
                    }

                    var userData = snapshot.data!;
                    String fName = userData['f_Name'] ?? 'Unknown';
                    String lName = userData['l_Name'] ?? 'Unknown';
                    String avatarUrl = userData['avatar_Url'] ?? '';
                    bool isActive = userData['isActive'] ?? false;
                    String memNumber = userData['mem_Number'] ?? '';
                    String memType = userData['mem_Type'] ?? '';

                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : AssetImage('assets/images/common/profile.png')
                                  as ImageProvider,
                        ),
                        SizedBox(height: 10),
                        Text(
                          '$fName $lName',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$memType - ',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text: isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.green.shade800
                                        : Colors.red.shade800),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '($memNumber)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey),
                        ),
                      ],
                    );
                  },
                ),
                // Expanded(
                //   child: TextButton.icon(
                //     onPressed: () {},
                //     icon: Icon(Icons.edit, size: 16, color: AppKolors.secondary,),
                //     label: Text("edit profile", style: TextStyle(color: AppKolors.secondary),),
                //   ),
                // ),
              ],
            ),
          )
        : SafeArea(
            bottom: false,
            child: Container(
              width: double.maxFinite,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0693e3), Color(0xFF057ab8)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 25,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 60,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppKolors.accent.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Image.asset(
                            Image_url,
                            height: 22,
                            width: 22,
                            color: Colors.white,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.dashboard_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
