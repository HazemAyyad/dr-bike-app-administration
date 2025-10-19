import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import 'product_details_widgets/sup_text_and_dis.dart';

class ProjectImages extends StatelessWidget {
  const ProjectImages({Key? key, required this.list}) : super(key: key);

  final List<String> list;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (list.isNotEmpty)
          const Row(
            children: [
              SupTextAndDis(
                showLine: false,
                title: 'projectOrProductsImages',
                discription: '',
              ),
            ],
          ),
        if (list.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                Row(
                  children: [
                    ...list.map(
                      (e) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5.r),
                            child: GestureDetector(
                              onTap: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: 'Dismiss',
                                  barrierColor: Colors.black.withAlpha(128),
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                  pageBuilder: (context, anim1, anim2) {
                                    return FullScreenZoomImage(
                                      imageUrl: e,
                                    );
                                  },
                                );
                              },
                              child: CachedNetworkImage(
                                cacheManager: CacheManager(
                                  Config(
                                    'imagesCache',
                                    stalePeriod: const Duration(days: 7),
                                    maxNrOfCacheObjects: 100,
                                  ),
                                ),
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  height: 150.h,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.fill,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                                ),
                                imageUrl: e,
                                fadeInDuration:
                                    const Duration(milliseconds: 200),
                                fadeOutDuration:
                                    const Duration(milliseconds: 200),
                                placeholder: (context, url) => SizedBox(
                                  height: 150.h,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
      ],
    );
  }
}
