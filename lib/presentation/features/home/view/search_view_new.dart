import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../widgets/widgets.dart';
import '../../ordering/ordering.dart';
import '../../outlet/outlet.dart';
import '../../rewards/reward.dart';
import '../../voucher/voucher.dart';
import '../home.dart';

class SearchViewNew extends StatefulWidget {
  final Function changeView;
  final String tabFor;
  const SearchViewNew({
    super.key,
    required this.changeView,
    required this.tabFor,
  });
  @override
  State<SearchViewNew> createState() => _SearchViewNewState();
}

class _SearchViewNewState extends State<SearchViewNew>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  late TabController _tabs;
  List<String> _history = [];
  String _submitted = '';
  static const _palette = AppDesign.directory;

  String get _historyKey {
    final user =
        Storage().email.isNotEmpty ? Storage().email : Storage().contact;
    return user.isEmpty ? 'searchHistory_guest' : 'searchHistory_$user';
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 1, vsync: this);
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _history = prefs.getStringList(_historyKey) ?? []);
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _history);
  }

  void _search(String value) {
    final query = value.trim();
    if (query == _submitted &&
        context.read<HomeBloc>().state is HomeProcessing) {
      return;
    }
    _searchFocus.unfocus();
    setState(() {
      _submitted = query;
      _searchController.text = query;
      if (query.isNotEmpty) {
        _history.remove(query);
        _history.insert(0, query);
        _history = _history.take(10).toList();
      }
    });
    if (query.isEmpty) {
      context.read<HomeBloc>().add(SearchClearLoad());
    } else {
      _persistHistory();
      context.read<HomeBloc>().add(
        SearchLoad(
          keywords: query,
          type:
              widget.tabFor == 'home'
                  ? 'all'
                  : widget.tabFor == 'brand'
                  ? 'merchant'
                  : 'voucher',
        ),
      );
    }
  }

  void _back() {
    if (widget.tabFor == 'voucher') {
      Navigator.of(context).pushNamedAndRemoveUntil(
        OderRoutes.voucher,
        (route) => false,
        arguments: VoucherParameters(
          selectedTab: 0,
          filterBy: 'all',
          filterValue: '1',
        ),
      );
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.tabFor != 'voucher',
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && widget.tabFor == 'voucher') _back();
    },
    child: Scaffold(
      backgroundColor: _palette.background,
      appBar: AppBar(
        backgroundColor: _palette.background,
        foregroundColor: _palette.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Search',
          style: TextStyle(
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.appBarTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  color: _palette.text,
                  fontSize: AppDesign.bodySize,
                  fontFamily: fontFamilyMain,
                ),
                decoration: InputDecoration(
                  hintText:
                      widget.tabFor == 'brand'
                          ? 'Search brands'
                          : widget.tabFor == 'voucher'
                          ? 'Search vouchers'
                          : 'Search brands, outlets and vouchers',
                  hintStyle: TextStyle(
                    color: _palette.muted,
                    fontSize: AppDesign.bodySize,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: _palette.muted),
                  suffixIcon:
                      _searchController.text.isEmpty
                          ? null
                          : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search('');
                              _searchFocus.requestFocus();
                            },
                          ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDesign.fieldRadius),
                    borderSide: BorderSide(color: _palette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDesign.fieldRadius),
                    borderSide: BorderSide(color: _palette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDesign.fieldRadius),
                    borderSide: BorderSide(color: _palette.action),
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeProcessing) {
                    return Center(
                      child: CircularProgressIndicator(color: _palette.action),
                    );
                  }
                  if (state is SearchLoaded) {
                    return _results(state.searchData ?? []);
                  }
                  if (state is SearchEmpty) {
                    return _message(
                      Icons.search_off_rounded,
                      'No results found',
                      'Try another name or keyword.',
                    );
                  }
                  if (state is HomeError || state is HomeNetworkError) {
                    return _message(
                      Icons.wifi_off_rounded,
                      'Unable to search',
                      'Please try again.',
                      retry: true,
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      if (_history.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recent searches',
                                style: TextStyle(
                                  color: _palette.text,
                                  fontSize: AppDesign.sectionTitleSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _history = []);
                                _persistHistory();
                              },
                              child: Text(
                                'Clear all',
                                style: TextStyle(color: _palette.action),
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _history
                                  .map(
                                    (query) => ActionChip(
                                      backgroundColor: colorBlueDidik
                                          .withValues(alpha: 0.1),
                                      side: BorderSide.none,
                                      avatar: Icon(
                                        Icons.history_rounded,
                                        color: _palette.muted,
                                        size: 18,
                                      ),
                                      label: Text(
                                        query,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () => _search(query),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ] else
                        _message(
                          Icons.search_rounded,
                          'Find something you like',
                          'Search for brands, outlets and vouchers.',
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _message(
    IconData icon,
    String title,
    String description, {
    bool retry = false,
  }) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 32,
          backgroundColor: colorBlueDidik.withValues(alpha: 0.1),
          child: Icon(icon, color: _palette.action, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _palette.text,
            fontSize: AppDesign.sectionTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(color: _palette.muted, fontSize: AppDesign.bodySize),
        ),
        if (retry)
          TextButton(
            onPressed: () => _search(_submitted),
            child: const Text('Try again'),
          ),
      ],
    ),
  );

  Widget _results(List<dynamic> raw) {
    final items =
        raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final type = item['type']?.toString() ?? 'Other';
      groups.putIfAbsent(type, () => []).add(item);
    }
    final keys =
        groups.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (_tabs.length != keys.length + 1) {
      final index = _tabs.index.clamp(0, keys.length);
      _tabs.dispose();
      _tabs = TabController(
        length: keys.length + 1,
        vsync: this,
        initialIndex: index,
      );
    }
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: _palette.action,
          unselectedLabelColor: _palette.muted,
          indicatorColor: _palette.tabIndicator,
          dividerColor: _palette.border,
          labelStyle: const TextStyle(
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.bodySize,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            const Tab(text: 'All'),
            ...keys.map(
              (key) => Tab(
                text:
                    key.isEmpty
                        ? 'Other'
                        : key[0].toUpperCase() + key.substring(1),
              ),
            ),
          ],
        ),
        Expanded(
          child:
              items.isEmpty
                  ? _message(
                    Icons.search_off_rounded,
                    'No results found',
                    'Try another name or keyword.',
                  )
                  : TabBarView(
                    controller: _tabs,
                    children: [
                      _resultList(items, 'all'),
                      ...keys.map((key) => _resultList(groups[key]!, key)),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _resultList(List<Map<String, dynamic>> items, String key) =>
      ListView.separated(
        key: PageStorageKey(key),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final name = item['name']?.toString() ?? '';
          final description = item['description']?.toString() ?? '';
          return Material(
            color: _palette.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.cardRadius),
              side: BorderSide(color: _palette.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openResult(item),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child:
                            (item['image']?.toString().trim() ?? '').isEmpty
                                ? ColoredBox(
                                  color: colorBlueDidik.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: _palette.muted,
                                  ),
                                )
                                : CachedImage(
                                  imageUrl: item['image']?.toString() ?? '',
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _palette.text,
                              fontSize: AppDesign.bodySize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _palette.muted,
                                fontSize: AppDesign.smallSize,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            item['type']?.toString() ?? '',
                            style: TextStyle(
                              color: _palette.action,
                              fontSize: AppDesign.captionSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _palette.muted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  void _openResult(Map<String, dynamic> item) {
    final id = item['id'].toString();
    final title = item['name']?.toString() ?? '';
    switch (item['type']) {
      case 'voucher':
        Navigator.pushNamed(
          context,
          OderRoutes.rewardDetails,
          arguments: RewardDetailsParameters(
            rewardId: id,
            title: title,
            indexPage: 2,
          ),
        );
        break;
      case 'merchant':
        Navigator.pushNamed(
          context,
          OderRoutes.orderingOutlet,
          arguments: OrderingOutletParameters(brandsId: id),
        );
        break;
      case 'outlet':
        Navigator.pushNamed(
          context,
          OderRoutes.outletDetails,
          arguments: OutletDetailsParameters(outletId: id, outlet: title),
        );
        break;
    }
  }
}
