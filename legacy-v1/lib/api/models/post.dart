import 'user.dart';

class Post {
  final int id;
  final String title;
  final String? body;
  final String? mediaUrl;
  final String mediaType;
  final String language;
  final User owner;
  final DateTime createdAt;
  final AnalysisStatus analysisStatus;
  final double analysisProgress;
  final String statusMessage;
  final String? shortTitle;
  final String? summaryEasy;
  final int? credibilityScore;
  final int? confidenceScore;
  final String? bias;
  final String? sentiment;
  final String? riskType;
  final String? historicalContext;

  final String? counterNarrative;
  final String? inconsistencyHighlights;
  final List<String> verifiableAlternatives;

  final String? altHeadlineNeutral;
  final String? altHeadlineSensational;
  final String? altHeadlineCalm;
  final AnalysisRaw? analysisRaw;
  final List<String> tags;
  final List<String> redFlags;
  final List<String> trustSignals;
  final List<Claim> claims;
  final bool isUpvoted;
  final bool isDownvoted;
  final int upvoteDownvoteCount;
  final int viewCount;
  final double? lat;
  final double? long;
  final List<ForensicArtifact> forensicArtifacts;
  final Map<String, dynamic>? groundingContext;
  final List<String> evidenceChain;
  final String? c2paStatus;
  final Map<String, dynamic>? visualForensics;

  Post({
    required this.id,
    required this.title,
    this.body,
    this.mediaUrl,
    required this.mediaType,
    required this.language,
    required this.owner,
    required this.createdAt,
    required this.analysisStatus,
    required this.analysisProgress,
    required this.statusMessage,
    this.shortTitle,
    this.summaryEasy,
    this.credibilityScore,
    this.confidenceScore,
    this.bias,
    this.sentiment,
    this.riskType,
    this.historicalContext,
    this.counterNarrative,
    this.inconsistencyHighlights,
    required this.verifiableAlternatives,
    this.altHeadlineNeutral,
    this.altHeadlineSensational,
    this.altHeadlineCalm,
    this.analysisRaw,
    required this.tags,
    required this.redFlags,
    required this.trustSignals,
    required this.claims,
    required this.isUpvoted,
    required this.isDownvoted,
    required this.upvoteDownvoteCount,
    required this.viewCount,
    this.lat,
    this.long,
    required this.forensicArtifacts,
    this.groundingContext,
    required this.evidenceChain,
    this.c2paStatus,
    this.visualForensics,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final List<Claim> claimsList = (json['claims'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((claimJson) => Claim.fromJson(claimJson))
        .toList();

    final List<String> tagsList = (json['tags'] as List? ?? [])
        .map((e) => (e is Map) ? e['tag']?.toString() ?? "" : e.toString())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final List<String> redFlagsList = (json['red_flags'] as List? ?? [])
        .map((e) => (e is Map) ? e['flag']?.toString() ?? "" : e.toString())
        .where((flag) => flag.isNotEmpty)
        .toList();

    final List<String> trustSignalsList = (json['trust_signals'] as List? ?? [])
        .map((e) => (e is Map) ? e['signal']?.toString() ?? "" : e.toString())
        .where((signal) => signal.isNotEmpty)
        .toList();

    final List<String> alternatives =
        (json['verifiable_alternatives'] as List? ?? [])
            .map((e) => e.toString())
            .toList();

    final List<ForensicArtifact> forensics =
        (json['forensic_artifacts'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((fJson) => ForensicArtifact.fromJson(fJson))
            .toList();

    final raw = (json['analysis_raw'] is Map<String, dynamic>)
        ? json['analysis_raw'] as Map<String, dynamic>
        : null;

    return Post(
      id: json['id'] ?? -1,
      title: json['title'] ?? "",
      body: json['body'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'] ?? "TEXT",
      language: json['language'] ?? "en",
      owner: User.fromJson(json['owner']),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? "") ??
          DateTime.now(),
      analysisStatus: _stringToAnalysisStatus(
        json['analysis_status']?.toString(),
      ),
      analysisProgress: (json['analysis_progress'] is num)
          ? (json['analysis_progress'] as num).toDouble()
          : 0.0,
      statusMessage: json['status_message'] ?? "No status available",
      shortTitle: json['short_title'],
      summaryEasy: json['summary_easy'],
      credibilityScore: json['credibility_score'],
      confidenceScore: json['confidence_score'],
      bias: json['bias'],
      sentiment: json['sentiment'],
      riskType: json['risk_type'],
      historicalContext: json['historical_context'],
      counterNarrative: json['counter_narrative'],
      inconsistencyHighlights: json['inconsistency_highlights'],
      verifiableAlternatives: alternatives,
      altHeadlineNeutral: json['alt_headline_neutral'],
      altHeadlineSensational: json['alt_headline_sensational'],
      altHeadlineCalm: json['alt_headline_calm'],
      analysisRaw: raw != null ? AnalysisRaw.fromJson(raw) : null,
      tags: tagsList,
      redFlags: redFlagsList,
      trustSignals: trustSignalsList,
      claims: claimsList,
      isUpvoted: json["is_upvoted"] ?? false,
      isDownvoted: json["is_downvoted"] ?? false,
      upvoteDownvoteCount: json["upvote_downvote_count"] ?? 0,
      viewCount: json["view_count"] ?? 0,
      lat: json["latitude"] != null
          ? (json["latitude"] as num).toDouble()
          : null,
      long: json["longitude"] != null
          ? (json["longitude"] as num).toDouble()
          : null,
      forensicArtifacts: forensics,
      groundingContext: json['grounding_context'] is Map<String, dynamic>
          ? json['grounding_context']
          : null,
      evidenceChain: (json['evidence_chain'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      c2paStatus: json['c2pa_status'],
      visualForensics: raw?['visual_forensics'] as Map<String, dynamic>?,
    );
  }

  Post copyWith({
    AnalysisStatus? analysisStatus,
    double? analysisProgress,
    String? statusMessage,
    int? credibilityScore,
    int? confidenceScore,
  }) {
    return Post(
      id: id,
      title: title,
      body: body,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      language: language,
      owner: owner,
      createdAt: createdAt,
      analysisStatus: analysisStatus ?? this.analysisStatus,
      analysisProgress: analysisProgress ?? this.analysisProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      shortTitle: shortTitle,
      summaryEasy: summaryEasy,
      credibilityScore: credibilityScore ?? this.credibilityScore,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      bias: bias,
      sentiment: sentiment,
      riskType: riskType,
      counterNarrative: counterNarrative,
      inconsistencyHighlights: inconsistencyHighlights,
      verifiableAlternatives: verifiableAlternatives,
      altHeadlineNeutral: altHeadlineNeutral,
      altHeadlineSensational: altHeadlineSensational,
      altHeadlineCalm: altHeadlineCalm,
      analysisRaw: analysisRaw,
      tags: tags,
      redFlags: redFlags,
      trustSignals: trustSignals,
      claims: claims,
      isUpvoted: isUpvoted,
      isDownvoted: isDownvoted,
      upvoteDownvoteCount: upvoteDownvoteCount,
      viewCount: viewCount,
      lat: lat,
      long: long,
      forensicArtifacts: forensicArtifacts,
      groundingContext: groundingContext,
      evidenceChain: evidenceChain,
      c2paStatus: c2paStatus,
      visualForensics: visualForensics,
    );
  }

  static AnalysisStatus _stringToAnalysisStatus(String? status) {
    if (status == null) return AnalysisStatus.pending;
    final cleanStatus = status.split('.').last.toUpperCase();
    switch (cleanStatus) {
      case 'PENDING':
        return AnalysisStatus.pending;
      case 'INGESTING':
        return AnalysisStatus.ingesting;
      case 'REFINING':
        return AnalysisStatus.refining;
      case 'VERIFYING':
        return AnalysisStatus.verifying;
      case 'GROUNDING':
        return AnalysisStatus.grounding;
      case 'FINALIZING':
        return AnalysisStatus.finalizing;
      case 'COMPLETED':
        return AnalysisStatus.completed;
      case 'FAILED':
        return AnalysisStatus.failed;
      default:
        return AnalysisStatus.pending;
    }
  }
}

class AnalysisStatusUpdate {
  final AnalysisStatus analysisStatus;
  final double analysisProgress;
  final String statusMessage;

  AnalysisStatusUpdate({
    required this.analysisStatus,
    required this.analysisProgress,
    required this.statusMessage,
  });

  factory AnalysisStatusUpdate.fromJson(Map<String, dynamic> json) {
    return AnalysisStatusUpdate(
      analysisStatus: Post._stringToAnalysisStatus(
        json['analysis_status']?.toString(),
      ),
      analysisProgress: (json['analysis_progress'] is num)
          ? (json['analysis_progress'] as num).toDouble()
          : 0.0,
      statusMessage: json['status_message'] ?? "",
    );
  }
}

enum AnalysisStatus {
  pending,
  ingesting,
  refining,
  verifying,
  grounding,
  finalizing,
  completed,
  failed,
}

class AnalysisRaw {
  final Map<String, dynamic> data;

  AnalysisRaw(this.data);

  factory AnalysisRaw.fromJson(Map<String, dynamic> json) {
    return AnalysisRaw(json);
  }
}

class Claim {
  final String text;
  final int? credibilityScore;
  final String? verdict;
  final String? confidence;
  final String? reason;
  final String? historicalContext;
  final List<String> sources;
  final List<String> factCheckSites;

  Claim({
    required this.text,
    this.credibilityScore,
    this.verdict,
    this.confidence,
    this.reason,
    this.historicalContext,
    required this.sources,
    required this.factCheckSites,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      text: json['text'] ?? "",
      credibilityScore: json['credibility_score'],
      verdict: json['verdict'],
      confidence: json['confidence'],
      reason: json['reason'],
      historicalContext: json['historical_context'],
      sources: (json['sources'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      factCheckSites: (json['fact_check_sites'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class ForensicArtifact {
  final double x;
  final double y;
  final String label;

  ForensicArtifact({required this.x, required this.y, required this.label});

  factory ForensicArtifact.fromJson(Map<String, dynamic> json) {
    return ForensicArtifact(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] ?? "Manipulation Detected",
    );
  }
}

class PostPin {
  final int id;
  final String title;
  final double? lat;
  final double? long;
  final int? credibilityScore;
  final String? riskType;
  final String? shortTitle;
  final String? summaryEasy;

  PostPin({
    required this.id,
    required this.title,
    this.lat,
    this.long,
    this.credibilityScore,
    this.riskType,
    this.shortTitle,
    this.summaryEasy,
  });

  factory PostPin.fromJson(Map<String, dynamic> json) {
    return PostPin(
      id: json['id'] ?? -1,
      title: json['title'] ?? "",
      lat: json["latitude"] != null ? (json["latitude"] as num).toDouble() : null,
      long: json["longitude"] != null ? (json["longitude"] as num).toDouble() : null,
      credibilityScore: json['credibility_score'],
      riskType: json['risk_type'],
      shortTitle: json['short_title'],
      summaryEasy: json['summary_easy'],
    );
  }
}
