/*
 * Copyright (C) 2020. by perol_notsf, All rights reserved
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pixez/component/md2_tab_indicator.dart';
import 'package:pixez/i18n.dart';
import 'package:pixez/main.dart';
import 'package:pixez/page/hello/ranking/rank_store.dart';
import 'package:pixez/page/hello/ranking/ranking_mode/rank_mode_page.dart';

class RankPage extends StatefulWidget {
  late ValueNotifier<bool> isFullscreen;
  late Function? toggleFullscreen;
  RankPage({
    Key? key,
    ValueNotifier<bool>? isFullscreen,
    this.toggleFullscreen,
  }) : super(key: key) {
    this.isFullscreen =
        isFullscreen == null ? ValueNotifier(false) : isFullscreen;
  }

  @override
  _RankPageState createState() => _RankPageState();
}

class _RankPageState extends State<RankPage>
    with AutomaticKeepAliveClientMixin {
  late RankStore rankStore;
  final modeList = [
    "day",
    "day_male",
    "day_female",
    "week_original",
    "week_rookie",
    "week",
    "month",
    "day_r18",
    "week_r18",
    "week_r18g"
  ];
  var boolList = Map<int, bool>();
  late DateTime nowDate;
  late StreamSubscription<String> subscription;
  String? dateTime;

  GlobalKey appBarKey = GlobalKey();
  ValueNotifier<double?> appBarHeightNotifier = ValueNotifier(null);

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    nowDate = DateTime.now();
    rankStore = RankStore()..init();
    int i = 0;
    modeList.forEach((element) {
      boolList[i] = false;
      i++;
    });
    super.initState();
    subscription = topStore.topStream.listen((event) {
      if (event == "200") {
        topStore.setTop((201 + index).toString());
      }
    });
  }

  String? toRequestDate(DateTime dateTime) {
    if (dateTime == null) {
      return null;
    }
    return "${dateTime.year}-${dateTime.month}-${dateTime.day}";
  }

  DateTime nowDateTime = DateTime.now();
  int index = 0;
  int tapCount = 0;

  // 获取AppBar的高度，方便实现动画
  Future<double> initAppBarHeight() async {
    Size? appBarSize =
        appBarKey.currentContext?.findRenderObject()?.paintBounds.size;
    if (appBarSize != null) {
      return appBarSize.height;
    } else {
      return 0;
    }
  }

  // 切换全屏状态
  void toggleFullscreen() async {
    if (appBarHeightNotifier.value == null) {
      appBarHeightNotifier.value = await initAppBarHeight();
      // 这里比较hack，因为需要等待appbarHeight从null到固定double类型的重绘
      // 等待50ms使组件重渲染完毕。
      Timer(const Duration(milliseconds: 50), () {
        toggleFullscreen();
      });
      return;
    }
    widget.toggleFullscreen!();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final rankListMean = I18n.of(context).mode_list.split(' ');
    return Observer(builder: (_) {
      if (rankStore.inChoice) {
        return _buildChoicePage(context, rankListMean);
      }
      if (rankStore.modeList.isNotEmpty) {
        var list = I18n.of(context).mode_list.split(' ');
        List<String> titles = [];
        for (var i = 0; i < rankStore.modeList.length; i++) {
          int index = modeList.indexOf(rankStore.modeList[i]);
          titles.add(list[index]);
        }
        return DefaultTabController(
          length: rankStore.modeList.length,
          child: Column(
            children: <Widget>[
              ValueListenableBuilder<double?>(
                valueListenable: appBarHeightNotifier,
                builder: (BuildContext context, double? value, Widget? child) =>
                    ValueListenableBuilder<bool>(
                        valueListenable: widget.isFullscreen,
                        builder: (BuildContext context, bool? isFullscreen,
                                Widget? child) =>
                            AnimatedContainer(
                              key: appBarKey,
                              duration: const Duration(milliseconds: 400),
                              height: isFullscreen != null && isFullscreen
                                  ? 0
                                  : appBarHeightNotifier.value,
                              child: AppBar(
                                elevation: 0.0,
                                title: TabBar(
                                  onTap: (i) => setState(() {
                                    this.index = i;
                                  }),
                                  indicator: MD2Indicator(
                                      indicatorHeight: 3,
                                      indicatorColor:
                                          Theme.of(context).colorScheme.primary,
                                      indicatorSize: MD2IndicatorSize.normal),
                                  indicatorSize: TabBarIndicatorSize.label,
                                  isScrollable: true,
                                  tabs: <Widget>[
                                    for (var i in titles)
                                      Tab(
                                        text: i,
                                      ),
                                  ],
                                ),
                                actions: <Widget>[
                                  if (widget.toggleFullscreen != null)
                                    IconButton(
                                      icon: Icon(Icons.fullscreen),
                                      onPressed: () {
                                        toggleFullscreen();
                                      },
                                    ),
                                  Visibility(
                                    visible: index < rankStore.modeList.length,
                                    child: IconButton(
                                      icon: Icon(Icons.date_range),
                                      onPressed: () async {
                                        await _showTimePicker(context);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.undo),
                                    onPressed: () {
                                      rankStore.reset();
                                    },
                                  )
                                ],
                              ),
                            )),
              ),
              Expanded(
                child: TabBarView(children: [
                  for (var element in rankStore.modeList)
                    RankModePage(
                      date: dateTime,
                      mode: element,
                      index: rankStore.modeList.indexOf(element),
                    ),
                ]),
              )
            ],
          ),
        );
      } else {
        return _buildChoicePage(context, rankListMean);
      }
    });
  }

  Widget _buildChoicePage(BuildContext context, List<String> rankListMean) {
    return Container(
      child: Column(
        children: <Widget>[
          AppBar(
            elevation: 0.0,
            title: Text(I18n.of(context).choice_you_like),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.save),
                onPressed: () async {
                  await rankStore.saveChange(boolList);
                  rankStore.inChoice = false;
                },
              )
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 4,
                children: [
                  for (var e in rankListMean)
                    FilterChip(
                        label: Text(e),
                        selected: _rankFilters.contains(e),
                        onSelected: (v) {
                          boolList[rankListMean.indexOf(e)] = v;
                          if (v) {
                            setState(() {
                              _rankFilters.add(e);
                            });
                          } else {
                            setState(() {
                              _rankFilters.remove(e);
                            });
                          }
                        }),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  List<String> _rankFilters = [];

  Future _showTimePicker(BuildContext context) async {
    var nowdate = DateTime.now();
    var date = await showDatePicker(
        context: context,
        initialDate: nowDateTime,
        locale: userSetting.locale,
        firstDate: DateTime(2007, 8),
        //pixiv于2007年9月10日由上谷隆宏等人首次推出第一个测试版...
        lastDate: nowdate);
    if (date != null && mounted) {
      nowDateTime = date;
      setState(() {
        this.dateTime = toRequestDate(date);
      });
    }
  }

  @override
  bool get wantKeepAlive => true;
}
