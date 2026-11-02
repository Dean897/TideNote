import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final String id, title, status;
  final String? instruction, proofImage;
  final DateTime deadline;
  final bool isUrgent;
  final VoidCallback? onViewProofImage;
  final VoidCallback onDelete, onToggleStatus, onToggleUrgency;
  const TaskCard({
    super.key,
    required this.id,
    required this.title,
    this.instruction,
    this.proofImage,
    required this.deadline,
    required this.status,
    required this.isUrgent,
    this.onViewProofImage,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onToggleUrgency,
  });
  factory TaskCard.fromMap(
    Map<String, dynamic> data, {
    required VoidCallback onDelete,
    required VoidCallback onToggleStatus,
    required VoidCallback onToggleUrgency,
    VoidCallback? onViewProofImage,
  }) {
    return TaskCard(
      id: data['id'],
      title: data['title'],
      instruction: data['instruction'],
      proofImage: data['proofImage'],
      deadline: data['deadline'],
      status: data['status'],
      isUrgent: data['isUrgent'] ?? false,
      onViewProofImage: onViewProofImage,
      onDelete: onDelete,
      onToggleStatus: onToggleStatus,
      onToggleUrgency: onToggleUrgency,
    );
  }
  @override
  Widget build(BuildContext context) {
    bool isDone = status == 'Done';
    bool isOverdue = deadline.isBefore(DateTime.now()) && !isDone;
    final remaining = deadline.difference(DateTime.now());
    Color deadlineColor = remaining > const Duration(hours: 48)
        ? const Color(0xFF86EFAC)
        : remaining >= const Duration(hours: 24)
        ? const Color(0xFFFDE047)
        : const Color(0xFFFCA5A5);

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (d) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDone
              ? const Color(0xFFF0FDF4)
              : (isOverdue ? const Color(0xFFFEF2F2) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone
                ? const Color(0xFF86EFAC)
                : (isOverdue ? const Color(0xFFFCA5A5) : deadlineColor),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? const Color(0xFF166534)
                          : (isOverdue
                                ? Colors.red.shade900
                                : const Color(0xFF334155)),
                    ),
                  ),
                ),
                if (instruction != null && instruction!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    instruction!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDone
                          ? const Color(0xFF15803D)
                          : (isOverdue
                                ? Colors.red.shade700
                                : Colors.grey.shade500),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(
                  color: isDone
                      ? const Color(0xFFDCFCE7)
                      : (isOverdue
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFF1F5F9)),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 12),
                if (isDone && proofImage != null) ...[
                  InkWell(
                    onTap: onViewProofImage,
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(proofImage!),
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Lihat fullsize',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: isDone
                              ? const Color(0xFF22C55E)
                              : (isOverdue
                                    ? Colors.red.shade400
                                    : Colors.grey.shade400),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM, HH:mm').format(deadline),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? const Color(0xFF166534)
                                : (isOverdue
                                      ? Colors.red.shade700
                                      : Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: isOverdue ? null : onToggleStatus,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFFDCFCE7)
                              : (isOverdue
                                    ? Colors.red.shade100
                                    : (status == 'In Progress'
                                          ? const Color(0xFFBFF4FF)
                                          : Colors.grey.shade100)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOverdue ? 'Terlambat' : status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? const Color(0xFF15803D)
                                : (isOverdue
                                      ? Colors.red.shade700
                                      : (status == 'In Progress'
                                            ? const Color(0xFF5AB2D3)
                                            : Colors.grey.shade600)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: -4,
              right: -4,
              child: IconButton(
                icon: Icon(
                  isUrgent
                      ? Icons.local_fire_department_rounded
                      : Icons.local_fire_department_outlined,
                  color: isDone
                      ? const Color(0xFF86EFAC)
                      : (isOverdue
                            ? Colors.red.shade300
                            : (isUrgent
                                  ? Colors.orange.shade400
                                  : Colors.grey.shade300)),
                  size: 24,
                ),
                onPressed: isDone || isOverdue ? null : onToggleUrgency,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
