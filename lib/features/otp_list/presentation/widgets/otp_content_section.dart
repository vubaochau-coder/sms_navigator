import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_event.dart';
import '../bloc/otp_list_state.dart';
import 'otp_content_view.dart';

/// Section chứa danh sách nội dung OTP kết nối với OtpListBloc (RefreshIndicator, Shimmer, OtpContentView).
class OtpContentSection extends StatelessWidget {
  const OtpContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpListBloc, OtpListState>(
      buildWhen: (previous, current) =>
          previous.isLoading != current.isLoading ||
          previous.items != current.items ||
          previous.groupedByDevice != current.groupedByDevice ||
          previous.isGroupingByDevice != current.isGroupingByDevice ||
          previous.selectedDate != current.selectedDate,
      builder: (context, state) {
        final dateDisplay = DateTimeUtils.formatDate(state.selectedDate);

        return RefreshIndicator(
          onRefresh: () async {
            context.read<OtpListBloc>().add(
                  const OtpListLoadEvent(),
                );
          },
          child: state.isLoading
              ? const ShimmerLoadingList()
              : OtpContentView(
                  items: state.items,
                  groupedByDevice: state.groupedByDevice,
                  isGroupingByDevice: state.isGroupingByDevice,
                  dateDisplay: dateDisplay,
                ),
        );
      },
    );
  }
}
