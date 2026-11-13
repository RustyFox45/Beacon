import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

class OtpInputRow extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final bool autofocus;

  const OtpInputRow({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.autofocus = true,
  });

  @override
  State<OtpInputRow> createState() => OtpInputRowState();
}

class OtpInputRowState extends State<OtpInputRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void clear() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  void requestFocus() => _focusNode.requestFocus();

  void _onChanged(String value) {
    setState(() {});
    if (value.length == widget.length) {
      widget.onCompleted(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final activeIndex = min(text.length, widget.length - 1);

    return Stack(
      children: [
        // Visual boxes — pointer events fall through to the hidden field below
        IgnorePointer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) {
              final isFocused = i == activeIndex;
              return Container(
                width: 44,
                height: 53,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primaryMidTeal
                        : AppColors.neutralCharcoal,
                    width: isFocused ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  i < text.length ? text[i] : '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }),
          ),
        ),
        // Hidden single TextField — holds focus and captures all input
        SizedBox(
          height: 53,
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              showCursor: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: _onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
