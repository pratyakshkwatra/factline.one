import 'package:auto_route/auto_route.dart';
import 'package:factline/api/post.dart';
import 'package:factline/services/auth.dart';
import 'package:factline/widgets/error_snackbar.dart';
import 'package:factline/widgets/normal_snackbar.dart';
import 'package:factline/widgets/textfield.dart';
import 'package:factline/router/router.gr.dart';
import 'package:factline/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:file_picker/file_picker.dart';

@RoutePage()
class AddPostScreen extends StatefulWidget {
  final AuthService authService;
  final FlutterSecureStorage secureStorage;
  const AddPostScreen({
    super.key,
    required this.authService,
    required this.secureStorage,
  });

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  int _currentStep = 0;
  String _selectedMediaType = "TEXT";
  bool _isLoading = false;
  String? _pickedFilePath;
  String? _pickedFileName;

  final List<Map<String, dynamic>> _mediaOptions = [
    {"label": "REPORT", "type": "TEXT", "icon": Icons.article_rounded},
    {"label": "LINK", "type": "LINK", "icon": Icons.link_rounded},
    {"label": "IMAGE", "type": "IMAGE", "icon": Icons.image_rounded},
    {"label": "AUDIO", "type": "AUDIO", "icon": Icons.mic_rounded},
    {"label": "VIDEO", "type": "VIDEO", "icon": Icons.videocam_rounded},
  ];

  final TextEditingController _urlController = TextEditingController();

  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && _selectedMediaType == "VIDEO") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: FactlineInter("Video Forensics coming soon")),
        );
        return;
      }

      if (_currentStep == 0 && _selectedMediaType == "TEXT") {
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep = 2);
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    } else {
      _submitPost();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      if (_currentStep == 2 && _selectedMediaType == "TEXT") {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep = 0);
      } else {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep--);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            FactlineInter(
              "Forensic Ingestion",
              style: GoogleFonts.merriweather(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            FactlineInter(
              "Step ${_currentStep + 1} of 3",
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
          _buildNavigation(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 2,
      width: double.infinity,
      color: Colors.white10,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (_currentStep + 1) / 3,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xffD90429),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffD90429).withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FactlineInter(
            "Select Evidence Type",
            style: GoogleFonts.merriweather(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FactlineInter(
            "Choose the primary medium of the story you are submitting for forensic analysis.",
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _mediaOptions.length,
              itemBuilder: (context, index) {
                final opt = _mediaOptions[index];
                final isSelected = _selectedMediaType == opt['type'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMediaType = opt['type']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xffD90429).withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xffD90429)
                            : Colors.white10,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          opt['icon'],
                          color: isSelected
                              ? const Color(0xffD90429)
                              : Colors.white38,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        FactlineInter(
                          opt['label'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : Colors.white24,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FactlineInter(
            _selectedMediaType == "LINK"
                ? "Intelligence Extraction"
                : "Ingest Evidence",
            style: GoogleFonts.merriweather(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FactlineInter(
            _selectedMediaType == "LINK"
                ? "Input the news URL. Our engine will crawl the source and begin forensic cross-referencing."
                : "Upload the raw $_selectedMediaType file. Our engine will scan for digital manipulation artifacts.",
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
          ),
          const SizedBox(height: 48),
          if (_selectedMediaType == "LINK")
            RoundedInputField(
              controller: _urlController,
              hintText: "https://reuters.com/news/...",
              icon: Icons.link_rounded,
              isPassword: false,
            )
          else
            Center(child: _buildFilePickerWidget()),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FactlineInter(
            "Contextual Matrix",
            style: GoogleFonts.merriweather(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FactlineInter(
            "Provide the narrative context. This aids our cross-referencing system in locating Truth Base matches.",
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
          ),
          const SizedBox(height: 40),
          RoundedInputField(
            controller: _titleController,
            hintText: "Heading / Primary Claim",
            icon: Icons.text_fields_rounded,
            isPassword: false,
          ),
          const SizedBox(height: 20),
          RoundedInputField(
            controller: _bodyController,
            hintText: "Optional Forensic Brief / Transcript",
            icon: Icons.article_outlined,
            isPassword: false,
            maxLines: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerWidget() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _pickedFilePath != null
                ? const Color(0xffD90429)
                : Colors.white10,
            width: 2,
            style: _pickedFilePath != null
                ? BorderStyle.solid
                : BorderStyle.none,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _pickedFilePath != null
                    ? const Color(0xffD90429).withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _pickedFilePath != null
                    ? Icons.check_circle_rounded
                    : Icons.cloud_upload_outlined,
                color: _pickedFilePath != null
                    ? const Color(0xffD90429)
                    : Colors.white10,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            FactlineInter(
              _pickedFileName ?? "BROWSE DEVICE STORAGE",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _pickedFilePath != null ? Colors.white : Colors.white24,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _prevStep,
              child: FactlineInter(
                "BACK",
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            )
          else
            const SizedBox(width: 60),
          GestureDetector(
            onTap: _isLoading ? null : _nextStep,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xffD90429),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffD90429).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : FactlineInter(
                      _currentStep == 2 ? "SUBMIT FOR ANALYSIS" : "NEXT PHASE",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: _getPickerType(),
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFilePath = result.files.single.path;
        _pickedFileName = result.files.single.name;
      });
      _nextStep();
    }
  }

  FileType _getPickerType() {
    switch (_selectedMediaType) {
      case "IMAGE":
        return FileType.image;
      case "AUDIO":
        return FileType.audio;
      case "VIDEO":
        return FileType.video;
      default:
        return FileType.any;
    }
  }

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final url = _urlController.text.trim();

    if (title.isEmpty) {
      showNormalSnackbar("Context Heading required", context);
      return;
    }

    if (_selectedMediaType == "LINK" && url.isEmpty) {
      showNormalSnackbar("Intelligence Link required", context);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? finalMediaUrl;
      const mediaFiles = ["IMAGE", "AUDIO", "VIDEO"];
      if (mediaFiles.contains(_selectedMediaType) && _pickedFilePath != null) {
        finalMediaUrl = await PostAPI().uploadMedia(_pickedFilePath!);
      }

      final post = await PostAPI().createPost(
        title: title,
        body: body,
        mediaUrl: finalMediaUrl,
        mediaType: _selectedMediaType == "LINK" ? "TEXT" : _selectedMediaType,
        sourceUrl: _selectedMediaType == "LINK" ? url : null,
      );

      if (mounted) {
        showNormalSnackbar("Intelligence successfully ingested", context);
        context.router.replace(
          NewsFullRoute(post: post, authService: widget.authService),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackbar("Ingestion Failure: $e", context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
