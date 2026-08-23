import 'package:flutter/material.dart';

class AuthFormFooter extends StatelessWidget {
  const AuthFormFooter({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        children: [
          Text(prompt, style: Theme.of(context).textTheme.bodySmall),
          TextButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
