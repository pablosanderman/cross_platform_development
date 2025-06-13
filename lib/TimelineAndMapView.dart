import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'timeline/timeline.dart';

import 'navigation/navigation.dart';

class TimelineMapView extends StatelessWidget{
  const TimelineMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, navState) {
          final bothVisible = navState.showTimeline
              && navState.showMap;
          return Expanded(
            child: Row(
              children: [
                if(navState.showTimeline)
                  Expanded(
                    flex: bothVisible ? 1 : 2,
                    child: const TimelinePage(),
                  ),
                if(navState.showMap)
                  Expanded(
                    flex: bothVisible ? 1 : 2,
                    child: const RightSide(),
                  ),
              ],
            ),
          );
        }

    );
  }
}


const backgroundStartColor = Color(0xFFFFD500);

class RightSide extends StatelessWidget {
  const RightSide({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        color: backgroundStartColor,
        child: Column(children: [Text("MAPMAPMAP")]),
      ),
    );
  }
}