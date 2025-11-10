import 'package:flutter/material.dart';
import 'side_menu.dart';
import 'app_header.dart';
import 'right_drawer.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final Widget? rightDrawerChild;

  const MainLayout({super.key, required this.child, this.rightDrawerChild});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  bool _isRightDrawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    final curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // 오른쪽에서 시작
      end: Offset.zero, // 제자리로
    ).animate(curvedAnimation);

    _buttonAnimation = Tween<double>(
      begin: -20.0,
      end: 230.0, // 250 - 20
    ).animate(curvedAnimation);

    // 애니메이션 상태 변경 리스너 추가
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {}); // 애니메이션이 완전히 끝나면 UI 업데이트
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleRightDrawer() {
    if (_isRightDrawerOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isRightDrawerOpen = !_isRightDrawerOpen;
    });
  }

  bool get _shouldShowDrawer {
    return _isRightDrawerOpen || _animationController.isAnimating;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          const SideMenu(),
          Expanded(
            child: Column(
              children: [
                // Header
                const AppHeader(),

                // Main Content with Right Drawer
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          // Main Content
                          Expanded(
                            flex: _isRightDrawerOpen ? 3 : 1,
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              child: widget.child,
                            ),
                          ),

                          // Right Drawer with Animation
                          if (_shouldShowDrawer)
                            SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                width: 250,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  border: const Border(
                                    left: BorderSide(
                                      color: Colors.grey,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child:
                                    widget.rightDrawerChild ??
                                    const RightDrawer(),
                              ),
                            ),
                        ],
                      ),

                      // Floating Toggle Button at the boundary with animation
                      AnimatedBuilder(
                        animation: _buttonAnimation,
                        builder: (context, child) {
                          return Positioned(
                            right: _buttonAnimation.value,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Material(
                                elevation: 4,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: _toggleRightDrawer,
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      transitionBuilder: (child, animation) {
                                        return RotationTransition(
                                          turns: animation,
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        _animationController.value > 0.5
                                            ? Icons.arrow_forward_ios
                                            : Icons.arrow_back_ios,
                                        key: ValueKey<bool>(
                                          _animationController.value > 0.5,
                                        ),
                                        size: 20,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
