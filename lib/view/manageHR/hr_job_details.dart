import 'package:flutter/material.dart';
import 'package:stackle_admin/data/models/job.dart' as job_model;
import 'package:stackle_admin/core/api_base.dart';
import 'package:stackle_admin/core/pdf_viewer.dart';

class HRJobDetailScreen extends StatelessWidget {
  final job_model.Job job;
  final String organizationName;
  const HRJobDetailScreen({Key? key, required this.job, required this.organizationName}) : super(key: key);

  String _resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    final trimmed = url.trim();
    final baseRoot = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final path = uri.path;
      final mediaIndex = path.indexOf('/media/');
      if (mediaIndex != -1) {
        final rel = path.substring(mediaIndex + '/media/'.length);
        return '${baseRoot.replaceAll(RegExp(r'/+$'), '')}/media/$rel';
      }
      try {
        if (Uri.parse(baseRoot).host == uri.host) return trimmed;
      } catch (_) {}
      return trimmed; // external URL
    }

    if (trimmed.startsWith('/media/')) {
      return '${baseRoot.replaceAll(RegExp(r'/+$'), '')}$trimmed';
    }
    final idx = trimmed.indexOf('/media/');
    if (idx != -1) {
      final rel = trimmed.substring(idx + '/media/'.length);
      return '${baseRoot.replaceAll(RegExp(r'/+$'), '')}/media/$rel';
    }
    final rel = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '${baseRoot.replaceAll(RegExp(r'/+$'), '')}/media/$rel';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.grey,),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: Colors.white)),
            const SizedBox(height: 2),
            Text(organizationName, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          if (job.id != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: _chip(Icons.tag, 'ID: ${job.id}'),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: _chip(job.isSubscribed ? Icons.verified : Icons.money_off, job.isSubscribed ? 'Subscribed' : 'Not Subscribed'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _content(theme),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _content(ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('Description', Text(job.description.isEmpty ? 'No description provided.' : job.description, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87))),
      const SizedBox(height: 24),
      _section('Qualification & Experience', Wrap(spacing: 16, runSpacing: 16, children: [
        _infoCard('Qualification', job.qualification.isEmpty ? 'N/A' : job.qualification),
        _infoCard('Experience', job.experienceYears != null ? '${job.experienceYears} years' : 'Not specified'),
        _infoCard('Salary', job.salary.isEmpty ? '—' : job.salary),
      ])),
      const SizedBox(height: 24),
      _section('Contact Info', Wrap(spacing: 16, runSpacing: 16, children: [
        _infoCard('Phone', job.phone.isEmpty ? '—' : job.phone),
        _infoCard('Email', job.email.isEmpty ? '—' : job.email),
        _infoCard('Location', '${job.city}, ${job.state}, ${job.country}'),
        _infoCard('Pincode', job.pincode),
      ])),
      const SizedBox(height: 24),
      if (job.jobTypes.isNotEmpty)
        _section('Job Types', Wrap(spacing: 8, runSpacing: 8, children: job.jobTypes.map((t) => _pill(t.jobType)).toList())),
      if (job.jobSkills.isNotEmpty) ...[
        const SizedBox(height: 24),
        _section('Skills', Wrap(spacing: 8, runSpacing: 8, children: job.jobSkills.map((s) => _pill(s.skill)).toList())),
      ],
      const SizedBox(height: 24),
      if (job.jobImages.isNotEmpty) _section('Images & Documents', _mediaGrid()),
    ]);
  }

  Widget _mediaGrid() {
    final items = job.jobImages;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];
        final url = _resolveMediaUrl(entry.url);
        final isPdf = url.toLowerCase().endsWith('.pdf');
        return GestureDetector(
          onTap: () {
            if (isPdf) {
              viewPdfInline(job.title, url, context);
            } else {
              showDialog(
                  context: context,
                  builder: (_) => Dialog(
                        child: Stack(children: [
                          Positioned.fill(
                            child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Text('Failed to load'))),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          )
                        ]),
                      ));
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: Stack(children: [
              Positioned.fill(
                child: isPdf
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                            SizedBox(height: 6),
                            Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image))),
                      ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blue)),
      );

  Widget _section(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      );

  Widget _infoCard(String title, String value) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
