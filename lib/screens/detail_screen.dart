import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:media_player/widgets/app_bar.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../core/constants.dart';
import '../widgets/image_widget.dart';
import '../widgets/text_widget.dart';
import 'bottom_bar_screen.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.entity});

  final AssetEntity entity;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool useOrigin = true;
  bool useMediaUri = true && !PlatformUtils.isOhos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:

      AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: AppImage(src: AppSvg.backArrowIcon, height: 20, width: 20),
          ),
        ),
        title:  AppText(
          widget.entity.title??"",
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.info), onPressed: _showInfo),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (widget.entity.type == AssetType.image)
            CheckboxListTile(
              title: const Text('Use origin file.'),
              onChanged: (bool? value) {
                useOrigin = value!;
                setState(() {});
              },
              value: useOrigin,
            ),
          if (widget.entity.type == AssetType.video && PlatformUtils.isOhos)
            CheckboxListTile(
              title: const Text('Use Media Uri'),
              value: useMediaUri,
              onChanged: (bool? value) {
                useMediaUri = value!;
                setState(() {});
              },
            ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              color: Colors.black,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.entity.isLivePhoto) {
      return LivePhotosWidget(
        entity: widget.entity,
        useOrigin: useOrigin == true,
      );
    }
    if (widget.entity.type == AssetType.audio ||
        widget.entity.type == AssetType.video ||
        widget.entity.isLivePhoto) {
      return buildVideo();
    }
    return buildImage();
  }

  Widget buildImage() {
    return AssetEntityImage(
      widget.entity,
      isOriginal: useOrigin == true,
      fit: BoxFit.fill,
      loadingBuilder:
          (BuildContext context, Widget child, ImageChunkEvent? progress) {
        if (progress == null) {
          return child;
        }
        final double? value;
        if (progress.expectedTotalBytes != null) {
          value =
              progress.cumulativeBytesLoaded / progress.expectedTotalBytes!;
        } else {
          value = null;
        }
        return Center(
          child: SizedBox.fromSize(
            size: const Size.square(30),
            child: CircularProgressIndicator(value: value),
          ),
        );
      },
    );
  }

  Widget buildVideo() {
    return VideoWidget(
      entity: widget.entity,
      usingMediaUri: useMediaUri ?? true,
    );
  }

  Future<void> _showInfo() {
    return showInfoDialog(context, widget.entity);
  }

  Widget buildAudio() {
    return const Center(child: Icon(Icons.audiotrack));
  }
}

Future<void> showInfoDialog(BuildContext context, AssetEntity entity) async {
  final LatLng? latlng = await entity.latlngAsync();
  final double? lat = latlng?.latitude ?? entity.latitude;
  final double? lng = latlng?.longitude ?? entity.longitude;

  final Widget w = Center(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(15),
        child: Material(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                child: _buildInfoItem('id', entity.id),
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: entity.id));
                  Fluttertoast.showToast(msg: 'The id already copied.');
                },
              ),
              _buildInfoItem('create', entity.createDateTime.toString()),
              _buildInfoItem('modified', entity.modifiedDateTime.toString()),
              _buildInfoItem('orientation', entity.orientation.toString()),
              _buildInfoItem('size', entity.size.toString()),
              _buildInfoItem('orientatedSize', entity.orientatedSize.toString()),
              _buildInfoItem('duration', entity.videoDuration.toString()),
              _buildInfoItemAsync('title', entity.titleAsync),
              // _buildInfoItem('lat', lat.toString()),
              // _buildInfoItem('lng', lng.toString()),
              _buildInfoItem('is favorite', entity.isFavorite.toString()),
              _buildInfoItem('relative path', entity.relativePath ?? 'null'),
              _buildInfoItemAsync('mimeType', entity.mimeTypeAsync),
            ],
          ),
        ),
      ),
    ),
  );
  showDialog<void>(context: context, builder: (BuildContext c) => w);
}

Widget _buildInfoItem(String title, String? info) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          alignment: Alignment.centerLeft,
          width: 90,
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: AppText(title,fontWeight: FontWeight.w500,),
          ),
        ),
        AppText(":",fontWeight: FontWeight.w500,),
        SizedBox(width: 20,),
        Expanded(child: AppText((info ?? 'null').padLeft(0),align: TextAlign.left,),),
      ],
    ),
  );
}

Widget _buildInfoItemAsync(String title, Future<String?> info) {
  return FutureBuilder<String?>(
    future: info,
    builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
      if (!snapshot.hasData) {
        return _buildInfoItem(title, '');
      }
      return _buildInfoItem(title, snapshot.data);
    },
  );
}