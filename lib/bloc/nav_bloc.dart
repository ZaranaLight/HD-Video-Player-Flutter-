import 'package:flutter_bloc/flutter_bloc.dart';

enum NavItem { dashboard, wishlist, easeCleaner  }

class NavBloc extends Bloc<NavItem, NavItem> {
  NavBloc() : super(NavItem.dashboard) {
    on<NavItem>((event, emit) => emit(event));
  }
}
