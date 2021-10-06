library twonky_api;

import 'dart:convert';
import 'package:http/http.dart' as http;

enum TransferOperation { start, stop, getstatus }

extension TransferOperationStr on TransferOperation {
  String get str {
    return this.toString().split('.').last;
  }
}

enum DtcpDownloadOperation { enabled, start, stop, finish, getstatus }

extension DtcpDownloadOperationStr on DtcpDownloadOperation {
  String get str {
    return this.toString().split('.').last;
  }
}

class Twonky {
  String hostname;
  int port;
  bool _initialised = false;
  late var _server;

  Twonky({required this.hostname, required this.port});

  get server => _server;
  get initialised => _initialised;

  // ******************************************************
  // Utility functions
  // ******************************************************

  Future<dynamic> _call({
    required String function,
    required Map<String, String?> parameters,
    String api = 'rpc',
  }) async {
    Map<String, String?> queryParameters = Map();
    parameters.forEach((key, value) {
      if (value != null) queryParameters[key] = value;
    });
    Uri uri = Uri(
      scheme: 'http',
      host: hostname,
      port: port,
      pathSegments: ['nmc', api, function],
      queryParameters: queryParameters,
    );
    // print('URI=${uri.toString()}');
    http.Response response = await http.get(uri);
    if (response.statusCode == 200) {
      var result;
      try {
        // print(response.body);
        result = jsonDecode(response.body);
        if (result['success'] != null && result['success'] == 'false')
          throw Exception(['Request failed', response]);
      } catch (e) {
        result = response.body;
      }
      return result;
    } else {
      throw Exception('Request error: ${response.statusCode}');
    }
  }

  String _hex(String string) {
    StringBuffer buffer = new StringBuffer();
    string.runes.forEach((element) {
      buffer.write('${element < 16 ? '0' : ''}${element.toRadixString(16)}');
    });
    return buffer.toString();
  }

  // ******************************************************
  // Twonky RSS calls
  // ******************************************************

  Future<dynamic> getServer() async {
    await getServers().then((servers) {
      for (var item in servers['item']) {
        var server = item['server'];
        if (server['name'] == 'Twonky') {
          _initialised = true;
          _server = server;
        }
      }
    });
  }

  Future<dynamic> getServers() => _call(
        function: 'servers',
        parameters: {'fmt': 'json'},
        api: 'rss',
      );

  Future<dynamic> getRenderers() => _call(
        function: 'renderers',
        parameters: {'fmt': 'json'},
        api: 'rss',
      );

  // ******************************************************
  // Twonky RPC calls
  // ******************************************************

  Future<dynamic> addBookmark({
    required String renderer,
    required String item,
    int? index,
  }) =>
      _call(
        function: 'add_bookmark',
        parameters: {
          'renderer': renderer,
          'item': item,
          'index': (index != null) ? index.toString() : null,
        },
      );

  Future<dynamic> addMetadata({
    required String renderer,
    required String url,
    String? metadata,
    int? index,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? albumArtURI,
    String? duration,
    String? creator,
    String? addlHdrs,
  }) {
    assert(
        (metadata != null && title == null) ||
            (title != null && metadata == null),
        'addMetadata: either metadata or title must be specified');
    return _call(
      function: 'add_metadata',
      parameters: {
        'renderer': renderer,
        'url': url,
        'metadata': metadata,
        'index': (index != null) ? index.toString() : null,
        'title': title,
        'artist': artist,
        'album': album,
        'genre': genre,
        'albumArtURI': albumArtURI,
        'duration': duration,
        'creator': creator,
        'addlHdrs': addlHdrs,
      },
    );
  }

  Future<dynamic> beam({
    required String renderer,
    required String beamUrl,
  }) =>
      _call(
        function: 'beam',
        parameters: {
          'renderer': renderer,
          'url': beamUrl,
        },
      );

  Future<dynamic> canPlay({
    required String renderer,
    required String item,
  }) =>
      _call(
        function: 'canPlay',
        parameters: {
          'renderer': renderer,
          'item': item,
        },
      );

  Future<dynamic> checkMultiuserAccess({
    required String server,
    required String user,
    required String password,
  }) =>
      _call(
        function: 'check_multiuser_access',
        parameters: {
          'server': server,
          'user': user,
          'password': password,
        },
      );

  Future<dynamic> clear({
    required String renderer,
  }) =>
      _call(
        function: 'clear',
        parameters: {
          'renderer': renderer,
        },
      );

  Future<dynamic> deleteItem({
    required String renderer,
    required int index,
  }) =>
      _call(
        function: 'delete_item',
        parameters: {
          'renderer': renderer,
          'index': index.toString(),
        },
      );

  Future<dynamic> download({
    required String bookmark,
    required TransferOperation operation,
    required String filename,
    bool json = false,
  }) =>
      _call(
        function: 'download',
        parameters: {
          'bookmark': bookmark,
          'operation': operation.str,
          'filename': filename,
          'fmt': (json) ? 'json' : null,
        },
      );

  Future<dynamic> dtcpContentUpload({
    required TransferOperation operation,
    required String src,
    required String dst,
  }) =>
      _call(
        function: 'dtcp_content_upload',
        parameters: {
          'operation': operation.str,
          'src': src,
          'dst': dst,
        },
      );

  Future<dynamic> dtcpContentDownload({
    required DtcpDownloadOperation operation,
    required String file,
  }) =>
      _call(
        function: 'dtcp_content_download',
        parameters: {
          'operation': operation.str,
          'file': file,
        },
      );

  Future<dynamic> dtcpGetCapabilities({
    required String src,
  }) =>
      _call(
        function: 'dtcp_get_capabilities',
        parameters: {
          'src': src,
        },
      );

  Future<dynamic> getAlbumart({
    required String renderer,
    int? index,
    int? maxEdge,
    String? mimeType,
    bool? ignoreDefault,
    String? scale,
    bool? device,
  }) =>
      _getIconUrl(
        renderer: renderer,
        index: index,
        maxEdge: maxEdge,
        mimeType: mimeType,
        ignoreDefault: ignoreDefault,
        scale: scale,
        device: (device != null) ? device : false,
      );

  Future<dynamic> getServerIconUrl({
    required String server,
    int? maxEdge,
    String? mimeType,
    bool? ignoreDefault,
    String? scale,
  }) =>
      _getIconUrl(
        server: server,
        maxEdge: maxEdge,
        mimeType: mimeType,
        ignoreDefault: ignoreDefault,
        scale: scale,
        device: true,
      );

  Future<dynamic> getRendererIconUrl({
    required String renderer,
    int? maxEdge,
    String? mimeType,
    bool? ignoreDefault,
    String? scale,
  }) =>
      _getIconUrl(
        renderer: renderer,
        maxEdge: maxEdge,
        mimeType: mimeType,
        ignoreDefault: ignoreDefault,
        scale: scale,
        device: true,
      );

  Future<dynamic> _getIconUrl({
    String? server,
    String? renderer,
    int? index,
    int? maxEdge,
    String? mimeType,
    bool? ignoreDefault,
    String? scale,
    bool device = false,
  }) {
    assert(server != null || renderer != null,
        '_getIconUrl: server or renderer must be specified');
    String type = (server != null) ? 'server' : 'renderer';
    String name = (server != null) ? server : renderer!;
    return _call(function: 'get_albumart', parameters: {
      type: name,
      'index': (index != null) ? index.toString() : null,
      'max_edge': (maxEdge != null) ? maxEdge.toString() : null,
      'mime_type': mimeType,
      'ignore_default': (ignoreDefault != null && ignoreDefault) ? '1' : '0',
      'scale': scale,
      'device': (device) ? '1' : '0',
    });
  }

  Future<dynamic> getCurrentPlayspeeds({
    required String renderer,
    bool? json,
  }) =>
      _call(function: 'get_current_playspeeds', parameters: {
        'renderer': renderer,
        'fmt': (json != null && json) ? 'json' : null,
      });

  Future<dynamic> getEvents({
    required String eventId,
  }) =>
      _call(function: 'get_events', parameters: {
        'eventid': eventId,
      });

  Future<dynamic> getItemPath({
    required String server,
    bool? json,
  }) =>
      _call(function: 'get_item_path', parameters: {
        'server': server,
        'fmt': (json != null && json) ? 'json' : null,
      });

  Future<dynamic> getKnownBookmarkMapping({
    required String server,
  }) =>
      _call(function: 'get_known_bookmark_mapping', parameters: {
        'server': server,
      });

  Future<dynamic> getMute({
    required String renderer,
  }) =>
      _call(function: 'get_mute', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> getNmcVersion() =>
      _call(function: 'get_nmc_version', parameters: {});

  Future<dynamic> getPlayindex({
    required String renderer,
    bool? getIsPlayIndexValid,
  }) =>
      _call(function: 'get_playindex', parameters: {
        'renderer': renderer,
        'getIsPlayIndexValid':
            (getIsPlayIndexValid != null && getIsPlayIndexValid) ? '1' : null,
      });

  Future<dynamic> getPlaymode({
    required String renderer,
    bool? json,
  }) =>
      _call(function: 'get_playmode', parameters: {
        'renderer': renderer,
        'fmt': (json != null && json) ? 'json' : null,
      });

  Future<dynamic> getPlayspeed({
    required String renderer,
  }) =>
      _call(function: 'get_playspeed', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> getSeekCapabilities({
    required String renderer,
  }) =>
      _call(function: 'get_seek_capabilities', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> getSlideshowDelay() =>
      _call(function: 'get_slideshow_delay', parameters: {});

  Future<dynamic> getState({
    required String renderer,
    bool? numeric,
  }) =>
      _call(function: 'get_state', parameters: {
        'renderer': renderer,
        'timeformat': (numeric != null && numeric) ? 'numeric' : null,
      });

  Future<dynamic> getStatus() => _call(function: 'get_state', parameters: {});

  Future<dynamic> getSupportedMimetypes({
    String? server,
    String? renderer,
    bool? json,
    bool? sortCaps,
    bool? searchCaps,
  }) {
    assert(
        (server != null && renderer == null) ||
            (server == null && renderer != null),
        'getSupportedMimetypes: server or renderer must be specified');
    assert(sortCaps == null || searchCaps == null,
        'getSupportedMimetypes: only one of sortCaps or searchCaps can be specified');
    return _call(function: 'get_supported_mimetypes', parameters: {
      'server': server,
      'renderer': renderer,
      'fmt': (json != null && json) ? 'json' : null,
      'sortcaps': (server != null && sortCaps != null && sortCaps) ? '1' : null,
      'searchcaps':
          (server != null && searchCaps != null && searchCaps) ? '1' : null,
    });
  }

  Future<dynamic> getVolumeDb({
    required String renderer,
  }) =>
      _call(function: 'get_volume_db', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> getVolumeDbRange({
    required String renderer,
  }) =>
      _call(function: 'get_volume_db_range', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> getVolumePercent({
    required String renderer,
  }) =>
      _call(function: 'get_volume_percent', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> logClear() => _call(function: 'log_clear', parameters: {});

  Future<dynamic> logDisable({
    required bool disable,
  }) =>
      _call(function: 'log_disable', parameters: {
        'mode': (disable) ? '1' : '0',
      });

  Future<dynamic> logGetFile() =>
      _call(function: 'log_getfile', parameters: {});

  Future<dynamic> logSet({
    required String sources,
    required String level,
  }) =>
      _call(function: 'log_set', parameters: {
        'sources': sources,
        'level': level,
      });

  Future<dynamic> moveTo({
    required String renderer,
    required int index,
    required int toIndex,
  }) =>
      _call(function: 'move_to', parameters: {
        'renderer': renderer,
        'index': index.toString(),
        'toindex': toIndex.toString(),
      });

  Future<dynamic> pause({
    required String renderer,
    required bool resume,
  }) =>
      _call(function: 'pause', parameters: {
        'renderer': renderer,
        'resume': (resume) ? '1' : '0',
      });

  Future<dynamic> play({
    required String renderer,
    int? mode,
    int? playSpeed,
  }) =>
      _call(function: 'play', parameters: {
        'renderer': renderer,
        'mode': (mode != null) ? mode.toString() : null,
        'playspeed': (playSpeed != null) ? playSpeed.toString() : null,
      });

  Future<dynamic> playFromPosition({
    required String renderer,
    String? bookmark,
    int? startPosMs,
    int? startPosByte,
  }) =>
      _call(function: 'play_from_position', parameters: {
        'renderer': renderer,
        'bookmark': bookmark,
        'startposms': (startPosMs != null) ? startPosMs.toString() : null,
        'startposbyte': (startPosByte != null) ? startPosByte.toString() : null,
      });

  Future<dynamic> resetAudiobookPosition({
    String? server,
    String? renderer,
  }) {
    assert(
        (server != null && renderer == null) ||
            (renderer != null && server == null),
        'resetAudiobookPosition: only one of server or renderer may be specified');
    return _call(function: 'reset_audiobook_position', parameters: {
      'renderer': renderer,
      'server': server,
    });
  }

  String queryString({
    String? artist,
    String? album,
    String? track,
    String? genre,
    int? year,
    required String type,
  }) {
    // String type = 'musicItem';
    // print(allItems);
    // if (album != null && track == null && (allItems == null || !allItems))
    //   type = 'musicAlbum';
    StringBuffer query = StringBuffer('type=$type');
    if (artist != null && artist != "")
      query.write('&artist=${Uri.encodeQueryComponent(artist)}');
    if (album != null && album != "") query.write('&album=${Uri.encodeQueryComponent(album)}');
    if (track != null && track != "") query.write('&title=${Uri.encodeQueryComponent(track)}');
    if (genre != null && genre != "") query.write('&genre=${Uri.encodeQueryComponent(genre)}');
    if (year != null && year != 0) query.write('&date=$year');
    return query.toString();
  }

  Future<dynamic> search({
    required String server,
    required String query,
    int? start,
    int? count,
    String? wkb,
    String? sort,
    String? fmt = 'json',
    bool? exact,
  }) =>
      _call(function: 'search', parameters: {
        'server': server,
        'search': _hex(query),
        'start': (start != null) ? start.toString() : null,
        'count': (count != null) ? count.toString() : null,
        'wkb': wkb,
        'sort': sort,
        'fmt': fmt,
        'exact': (exact != null && exact) ? '1' : null,
      });

  Future<dynamic> seekBytes({
    required String renderer,
    required int seek,
  }) =>
      _call(function: 'seek_bytes', parameters: {
        'renderer': renderer,
        'seek': seek.toString(),
      });

  Future<dynamic> seekPercent({
    required String renderer,
    required int seek,
  }) =>
      _call(function: 'seek_percent', parameters: {
        'renderer': renderer,
        'seek': seek.toString(),
      });

  Future<dynamic> seekTime({
    required String renderer,
    required int seek,
  }) =>
      _call(function: 'seek_time', parameters: {
        'renderer': renderer,
        'seek': seek.toString(),
      });

  Future<dynamic> setMute({
    required String renderer,
    required bool mute,
  }) =>
      _call(function: 'set_mute', parameters: {
        'renderer': renderer,
        'mute': (mute) ? '1' : '0',
      });

  Future<dynamic> setPlaymode({
    required String renderer,
    int? mode,
  }) =>
      _call(function: 'set_playmode', parameters: {
        'renderer': renderer,
        'mode': (mode != null) ? mode.toString() : null,
      });

  Future<dynamic> setPlayspeed({
    required String renderer,
    int? playspeed,
  }) =>
      _call(function: 'set_playspeed', parameters: {
        'renderer': renderer,
        'playspeed': (playspeed != null) ? playspeed.toString() : null,
      });

  Future<dynamic> setBrightness({
    required String renderer,
    required int brightness,
  }) =>
      _call(function: 'set_brightness', parameters: {
        'renderer': renderer,
        'brightness': brightness.toString(),
      });

  Future<dynamic> getBrightness({
    required String renderer,
  }) =>
      _call(function: 'get_brightness', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> setContrast({
    required String renderer,
    required int contrast,
  }) =>
      _call(function: 'set_contrast', parameters: {
        'renderer': renderer,
        'contrast': contrast.toString(),
      });

  Future<dynamic> getContrast({
    required String renderer,
  }) =>
      _call(function: 'get_contrast', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> setLoudness({
    required String renderer,
    required int loudness,
  }) =>
      _call(function: 'set_loudness', parameters: {
        'renderer': renderer,
        'loudness': loudness.toString(),
      });

  Future<dynamic> getLoudness({
    required String renderer,
  }) =>
      _call(function: 'get_loudness', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> setPlayindex({
    required String renderer,
    required int index,
  }) =>
      _call(function: 'set_playindex', parameters: {
        'renderer': renderer,
        'index': index.toString(),
      });

  Future<dynamic> skipNext({
    required String renderer,
    int? index,
    bool? json,
  }) =>
      _call(function: 'skip_next', parameters: {
        'renderer': renderer,
        'index': (index != null) ? index.toString() : null,
        'fmt': (json != null && json) ? 'json' : null,
      });

  Future<dynamic> skipPrevious({
    required String renderer,
    int? index,
    bool? json,
  }) =>
      _call(function: 'skip_previous', parameters: {
        'renderer': renderer,
        'index': (index != null) ? index.toString() : null,
        'fmt': (json != null && json) ? 'json' : null,
      });

  Future<dynamic> setSlideshowDelay({
    required String renderer,
    required int delay,
  }) =>
      _call(function: 'set_slideshow_delay', parameters: {
        'renderer': renderer,
        'delay': delay.toString(),
      });

  Future<dynamic> setVolumeDb({
    required String renderer,
    required int volume,
  }) =>
      _call(function: 'set_volume_db', parameters: {
        'renderer': renderer,
        'volume': volume.toString(),
      });

  Future<dynamic> setVolumePercent({
    required String renderer,
    required int volume,
  }) =>
      _call(function: 'set_volume_percent', parameters: {
        'renderer': renderer,
        'volume': volume.toString(),
      });

  Future<dynamic> stop({required String renderer}) =>
      _call(function: 'stop', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> upload({
    required String server,
    required String file,
    required TransferOperation operation,
  }) =>
      _call(function: 'upload', parameters: {
        'server': server,
        'file': file,
        'operation': operation.str,
      });

  Future<dynamic> createItemBookmark({
    required String server,
    required String objectId,
  }) =>
      _call(function: 'create_item_bookmark', parameters: {
        'server': server,
        'objectid': objectId,
      });

  Future<dynamic> canGroup({
    required String renderer,
    required String slave,
  }) =>
      _call(function: 'can_group', parameters: {
        'renderer': renderer,
        'slave': slave,
      });

  Future<dynamic> addSlave({
    required String renderer,
    required String slave,
  }) =>
      _call(function: 'add_slave', parameters: {
        'renderer': renderer,
        'slave': slave,
      });

  Future<dynamic> removeSlave({
    required String renderer,
    required String slave,
  }) =>
      _call(function: 'remove_slave', parameters: {
        'renderer': renderer,
        'slave': slave,
      });

  Future<dynamic> getSlaves({
    required String renderer,
  }) =>
      _call(function: 'get_slaves', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> isSlave({
    required String renderer,
  }) =>
      _call(function: 'is_slave', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> isMaster({
    required String renderer,
  }) =>
      _call(function: 'is_master', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> getMaster({
    required String renderer,
  }) =>
      _call(function: 'get_master', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> setGroupVolume({
    required String renderer,
    required int volume,
  }) =>
      _call(function: 'set_group_volume', parameters: {
        'renderer': renderer,
        'volume': volume.toString(),
      });

  Future<dynamic> getGroupVolume({
    required String renderer,
  }) =>
      _call(function: 'get_group_volume', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> setGroupMute({
    required String renderer,
    required bool mute,
  }) =>
      _call(function: 'set_group_mute', parameters: {
        'renderer': renderer,
        'mute': (mute) ? '1' : '0',
      });

  Future<dynamic> getGroupMute({
    required String renderer,
  }) =>
      _call(function: 'get_group_mute', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> disconnect({
    required String renderer,
  }) =>
      _call(function: 'disconnect', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> ioctlNmc({
    required String nmcIoctl,
    required String param,
  }) =>
      _call(function: 'ioctl_nmc', parameters: {
        nmcIoctl + '%20' + param: null,
      });

  Future<dynamic> ioctlDms({
    required String server,
    required String serverIoctl,
    required String param,
  }) =>
      _call(function: 'ioctl_dms', parameters: {
        'server': server,
        serverIoctl + '%20' + param: null,
      });

  Future<dynamic> ioctlDmr({
    required String renderer,
    required String rendererIoctl,
    required String param,
  }) =>
      _call(function: 'ioctl_dmr', parameters: {
        'renderer': renderer,
        rendererIoctl + '%20' + param: null,
      });

  Future<dynamic> deleteServerObject({
    required String server,
  }) =>
      _call(function: 'delete_server_object', parameters: {
        'server': server,
      });

  Future<dynamic> setMetadata({
    required String server,
    required String key,
    required String value,
    int? index,
  }) =>
      _call(function: 'set_metadata', parameters: {
        'server': server,
        'key': key,
        'value': value,
        'index': (index != null) ? index.toString() : null,
      });

  Future<dynamic> dumpRendererInfo({
    required String renderer,
  }) =>
      _call(function: 'dump_renderer_info', parameters: {
        'renderer': renderer,
      });

  Future<dynamic> getOnlineStatus({
    required String device,
  }) =>
      _call(function: 'get_online_status', parameters: {
        'device': device,
      });

  Future<dynamic> persistDevice({
    String? device,
    String? key,
    required bool persist,
  }) {
    assert((device != null && key == null) || (key != null && device == null),
        'persistDevice: one of device or key must be specified');
    return _call(function: 'persist_device', parameters: {
      'device': device,
    });
  }

  Future<dynamic> getPersistentDeviceList() =>
      _call(function: 'get_persistent_device_list', parameters: {});

  Future<dynamic> resetSpecific({
    required String gateway,
  }) =>
      _call(function: 'reset_specific', parameters: {
        'gateway': gateway,
      });
}
