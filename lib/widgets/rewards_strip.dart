// rewards_strip.dart, to hold and display the available rewards and achieved ones

import 'package:flutter/material.dart';

class RewardsStrip extends StatelessWidget {
  final int itemCount;

  const RewardsStrip(
      {super.key, this.itemCount = 8 // placeholder count, update later
      });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.grey.shade300),
              ),
              const SizedBox(height: 6),
              Container(
                width: 60,
                height: 10,
                color: Colors.grey.shade300,
              )
            ],
          );
        },
      ),
    );
  }
}
