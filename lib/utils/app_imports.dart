// ===========================================================================
// 1. DART & FLUTTER CORE ENGINES
// ===========================================================================
export 'dart:async';
export 'dart:io';
export 'dart:typed_data';
export 'dart:ui'
    hide
    Gradient,
    Image,
    BoxHeightStyle,
    BoxWidthStyle,
    decodeImageFromList,
    TextStyle,
    StrutStyle,
    TextHeightBehavior,
    Paint,
    ImageDecoderCallback;

export 'package:flutter/material.dart';
export 'package:flutter/cupertino.dart'
    hide RefreshCallback, Gradient, TextStyle;
export 'package:flutter/services.dart';
export 'package:flutter_localizations/flutter_localizations.dart';

// ===========================================================================
// 2. EXTERNAL PLUGINS & PACKAGES (Third Party)
// ===========================================================================
// UI & Animations
export 'package:flutter_svg/flutter_svg.dart';
export 'package:lottie/lottie.dart';
export 'package:shimmer/shimmer.dart';
export 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Audio & Video
export 'package:just_audio/just_audio.dart';
export 'package:audio_session/audio_session.dart';
export 'package:video_player/video_player.dart';
export 'package:chewie/chewie.dart';

// Media & Storage
export 'package:photo_manager/photo_manager.dart';
export 'package:photo_manager/platform_utils.dart';
export 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
export 'package:hive/hive.dart';
export 'package:hive_flutter/hive_flutter.dart';

// Utilities & Services
export 'package:flutter_bloc/flutter_bloc.dart';
export 'package:provider/provider.dart';
export 'package:share_plus/share_plus.dart';
export 'package:url_launcher/url_launcher.dart';
export 'package:in_app_review/in_app_review.dart';
export 'package:google_mobile_ads/google_mobile_ads.dart';
export 'package:fluttertoast/fluttertoast.dart';

// ===========================================================================
// 3. STATE MANAGEMENT (BLOCS)
// ===========================================================================
// Core Logic Blocs
export 'package:media_player/blocs/audio/audio_bloc.dart';
export 'package:media_player/blocs/video/video_bloc.dart';
export 'package:media_player/blocs/video/video_event.dart' hide RefreshCounts;
export 'package:media_player/blocs/video/video_state.dart';
export 'package:media_player/blocs/media/media_bloc.dart';
export 'package:media_player/blocs/player/player_bloc.dart';

// UI & Navigation Blocs
export 'package:media_player/blocs/home/home_tab_bloc.dart';
export 'package:media_player/blocs/home/home_tab_event.dart';
export 'package:media_player/blocs/home/home_tab_state.dart';
export 'package:media_player/blocs/bottom_nav/botton_nav_bloc.dart';
export 'package:media_player/blocs/bottom_nav/bottom_nav_event.dart';
export 'package:media_player/blocs/bottom_nav/bottom_nav_state.dart';

// Theme & Settings Blocs
export 'package:media_player/blocs/theme/theme_bloc.dart';
export 'package:media_player/blocs/theme/theme_event.dart';
export 'package:media_player/blocs/theme/theme_state.dart';

// Functional Blocs (Fav, Count, Local)
export 'package:media_player/blocs/favourite/favourite_bloc.dart';
export 'package:media_player/blocs/favourite/favourite_state.dart';
export 'package:media_player/blocs/count/count_bloc.dart';
export 'package:media_player/blocs/count/count_event.dart';
export 'package:media_player/blocs/count/count_state.dart';
export 'package:media_player/blocs/local/local_bloc.dart';
export 'package:media_player/blocs/local/local_event.dart';
export 'package:media_player/blocs/local/local_state.dart';

// ===========================================================================
// 4. DATA MODELS & CORE SERVICES
// ===========================================================================
export 'package:media_player/models/media_item.dart';
export 'package:media_player/models/playlist_model.dart';
export 'package:media_player/services/global_player.dart';
export 'package:media_player/services/hive_service.dart';
export 'package:media_player/services/playlist_service.dart';
export 'package:media_player/services/responsive_helper.dart';
export 'package:media_player/core/constants.dart';
export 'package:media_player/utils/app_colors.dart';
export 'package:media_player/utils/app_string.dart';

// ===========================================================================
// 5. SCREENS (UI LAYERS)
// ===========================================================================
export 'package:media_player/main.dart';
export 'package:media_player/screens/splash_screen.dart';
export 'package:media_player/screens/onboarding_screen.dart';
export 'package:media_player/screens/home_screen.dart';
export 'package:media_player/screens/bottom_bar_screen.dart';
export 'package:media_player/screens/audio_screen.dart';
export 'package:media_player/screens/video_screen.dart';
export 'package:media_player/screens/player_screen.dart';
export 'package:media_player/screens/mini_player.dart';
export 'package:media_player/screens/playlist_screen.dart';
export 'package:media_player/screens/favourite_screen.dart';
export 'package:media_player/screens/recent_screen.dart';
export 'package:media_player/screens/search_screen.dart';
export 'package:media_player/screens/setting_screen.dart';
export 'package:media_player/screens/language_screen.dart';
export 'package:media_player/screens/folder_screen.dart';
export 'package:media_player/screens/detail_screen.dart';
export 'package:media_player/screens/gallary_content_list_screen.dart';

// ===========================================================================
// 6. REUSABLE WIDGETS
// ===========================================================================
export 'package:media_player/widgets/text_widget.dart';
export 'package:media_player/widgets/image_widget.dart';
export 'package:media_player/widgets/favourite_button.dart';
export 'package:media_player/widgets/search_button.dart';
export 'package:media_player/widgets/app_button.dart';
export 'package:media_player/widgets/app_bar.dart';
export 'package:media_player/widgets/common_methods.dart';
export 'package:media_player/widgets/custom_loader.dart';
export 'package:media_player/widgets/app_toast.dart';
export 'package:media_player/widgets/app_transition.dart';
export 'package:media_player/widgets/add_to_playlist.dart';
export 'package:media_player/widgets/home_card.dart';
export 'package:media_player/widgets/image_item_widget.dart';
export 'package:media_player/widgets/gallary_item_widget.dart';
export 'package:media_player/widgets/shimmer_effect.dart';
export 'package:media_player/widgets/customa_shape.dart';

export 'package:media_player/blocs/media/media_event.dart';
export 'package:media_player/blocs/media/media_state.dart';