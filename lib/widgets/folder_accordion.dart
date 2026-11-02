import 'package:flutter/material.dart';

class FolderAccordion extends StatelessWidget {
  final String folderName;
  final int taskCount;
  final List<Widget> children;
  final bool isSubFolder;
  final VoidCallback? onDelete;
  const FolderAccordion({
    super.key,
    required this.folderName,
    required this.taskCount,
    required this.children,
    this.isSubFolder = false,
    this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: isSubFolder ? const EdgeInsets.only(left: 16) : EdgeInsets.zero,
      decoration: isSubFolder
          ? const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFDFF6FF), width: 2),
              ),
            )
          : null,
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFBFF4FF).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                color: Color(0xFF8DBEE1),
                size: 16,
              ),
            ),
            title: Text(
              folderName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSubFolder ? 13 : 14,
                color: const Color(0xFF334155),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$taskCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                if (onDelete != null && folderName != 'Lainnya') ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            childrenPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 8,
            ),
            children: children.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Belum ada tugas di folder ini',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ]
                : children,
          ),
        ),
      ),
    );
  }
}
