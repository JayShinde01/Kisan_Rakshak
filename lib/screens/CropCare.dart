import 'package:flutter/material.dart';

class Cropcare extends StatefulWidget {
  const Cropcare({super.key});

  @override
  State<Cropcare> createState() => _CropcareState();
}

class _CropcareState extends State<Cropcare> {
  // Enhanced wheat disease data structure (Data remains the same)
  List<Map<String, dynamic>> wheatDiseases = [
    {
      "name": "Wheat Rust (Stem, Leaf, Stripe)",
      "image": "https://cs-assets.bayer.com/is/image/bayer/leaf-rust-fungicide-crop-protection",
      "images": [
        "https://agritech.tnau.ac.in/crop_protection/images/wheat_diseases/wheat%20leaf%20rust%20nice_1.jpg",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS-7U7YfomxIWhHuynuRzuMuWl9phM_Asll4ftH-Pfmjyj0chiFbSGwMy1-K9Spt5qSpt5qSCSXAxCgdJmvLNonuCkbLI4MqBFtQvOBPNdWQXJM&s=10",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTQRILE_7c68t0UBENe4gHAgbdly3P4wXuDfdD3AulCsljPDgmygMlwm5o8nAIWtiY8b-k&usqp=CAU"
      ],
      "cause": "Fungal infection by Puccinia species (P. graminis, P. triticina, P. striiformis)",
      "symptoms": [
        "Orange/yellow **rust pustules** on leaves and stems.",
        "Pustules rupture, releasing powdery spores.",
        "Reduced grain size and shriveled grains.",
        "Stunted growth in severe cases."
      ],
      "prevention": [
        "Use **rust-resistant varieties** appropriate for your region.",
        "Apply specialized **fungicides** (e.g., Triazoles) timely.",
        "Avoid late sowing, which can increase vulnerability."
      ],
      "severity": "high",
      "onset": "Throughout season",
      "recommended_pesticide": "Propiconazole or Azoxystrobin",
      "dosage": "As per product instructions (e.g., 500ml/ha)",
      "how_people_handled": [
        "Many farmers in Punjab report good results with a single spray of Propiconazole at flag leaf stage.",
        "Some use resistant seeds but still monitor closely during rainy periods."
      ]
    },
    {
      "name": "Karnal Bunt (Partial Bunt)",
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSgbV5uAtM9AjJ9SbupvfmpdRwTyAhQ4Yo7hA&s",
      "images": [
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSgbV5uAtM9AjJ9SbupvfmpdRwTyAhQ4Yo7hA&s",
        "https://www.tribuneindia.com/sortd-service/imaginary/v22-01/jpg/large/high?url=dGhldHJpYnVuZS1zb3J0ZC1wcm8tcHJvZC1zb3J0ZC9tZWRpYTU3ZGM3MmUwLTJhMmYtMTFmMC04NDBiLTBkMWUyZGMyZWRkYi5qcGc=",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTCn8Bie6a5vhyVaIHx-wpzSL3c3WTjCznFyMsxGf6XAFBCl_saVkREaD8Qweup3SYl_NM&usqp=CAU"
      ],
      "cause": "Fungus: Tilletia indica (a seed and soil-borne disease)",
      "symptoms": [
        "**Black powdery fungal masses** replacing parts of the wheat kernels.",
        "Strong, unpleasant **fishy smell** (trimethylamine) from infected grains.",
        "Reduced grain quality, unfit for consumption."
      ],
      "prevention": [
        "Use **seed treatment** with fungicides like Tebuconazole.",
        "Practice **crop rotation** to reduce pathogen load in the soil.",
        "Avoid excessive irrigation, especially during flowering time."
      ],
      "severity": "moderate",
      "onset": "Flowering to maturity",
      "recommended_pesticide": "Tebuconazole (as seed treatment)",
      "how_people_handled": [
        "Seed treatment worked well, but irrigation control was difficult during unexpected rain."
      ]
    },
    {
      "name": "Powdery Mildew",
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTyb9wJxHN_PWcoNDcnI532gWfzfx3UckdyBg&s",
      "images": [
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTyb9wJxHN_PWcoNDcnI532gWfzfx3UckdyBg&s",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoEAdqkfEsPyNIz2sTmD15JHcLFlMwO5HUMg&s",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTuyip00FD6WBkem6TfDLQ118QQ90bjeT10Yw&s"
      ],
      "cause": "Fungus: Blumeria graminis (thrives in cool, humid conditions)",
      "symptoms": [
        "Distinctive **white powdery patches** on the upper surface of leaves and stems.",
        "Patches turn gray/brown over time.",
        "Reduced ability of the plant to photosynthesize."
      ],
      "prevention": [
        "Avoid **dense planting** to ensure good airflow.",
        "Apply **sulphur-based fungicides** early on.",
        "Select and use resistant cultivars if known to be a local issue."
      ],
      "severity": "low",
      "onset": "Early spring",
      "recommended_pesticide": "Sulfur wettable powder or Triadimefon",
      "dosage": "2 kg/ha (Sulphur)",
      "how_people_handled": []
    },
    {
      "name": "Loose Smut",
      "image":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQy9Gfg3q2jsjb1sSWsWIW7GRdnnr9L0p9xiQ&s",
      "images": [
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTAyurMnkFeSpFd5-wVAUZ_kYbPWcQ1ImkpSg&s",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQuDBMSatQIYvUxClXkCTxaiiveRG5q-K_StA&s",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQoeO_Cg3mtZ8ADm0DXDy23qstTxd5fMLl2Iw&s"
      ],
      "cause": "Fungus: Ustilago tritici (carried inside seed embryo)",
      "symptoms": [
        "Entire wheat ear replaced by black, sooty spores.",
        "Infected ears emerge earlier.",
        "Spores easily blow away leaving bare stalk."
      ],
      "prevention": [
        "Use disease-free certified seeds.",
        "Hot water seed treatment.",
        "Apply systemic seed fungicides like Carboxin."
      ],
      "severity": "moderate",
      "onset": "Heading stage",
      "recommended_pesticide": "Carboxin or Tebuconazole",
      "how_people_handled": [
        "Many farmers use certified seed to avoid infection.",
        "Hot-water seed treatment significantly reduced spread in many areas."
      ]
    },
    {
      "name": "Barley Yellow Dwarf Virus (BYDV)",
      "image":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS8a1TSKYVt3b5ivcUB1Ix32ongjMbztJpKDQ&s",
      "images": [
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS8a1TSKYVt3b5ivcUB1Ix32ongjMbztJpKDQ&s",
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSmlIhnhQEZcL09cePf2PmCVPHVga4sIrvyOA&s",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Barley_Yellow_Dwarf_Virus_in_wheat.jpg/250px-Barley_Yellow_Dwarf_Virus_in_wheat.jpg"
      ],
      "cause": "Virus spread by aphids",
      "symptoms": [
        "Yellowing and reddening of leaf tips.",
        "Severe stunting.",
        "Poor tillering and reduced yield."
      ],
      "prevention": [
        "Control aphids early using insecticides.",
        "Remove alternate host weeds.",
        "Use resistant varieties."
      ],
      "severity": "high",
      "onset": "Early growth stages",
      "recommended_pesticide": "Imidacloprid (controls aphids)",
      "treatment": [
        "No direct cure for BYDV virus.",
        "Control aphid carriers to prevent spread."
      ],
      "how_people_handled": [
        "Farmers observed improved yields after early aphid management.",
        "Removing wild grasses near fields reduced infection rate."
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // We expect the scaffold background and app bar background to be set by the parent Home Screen.

    return Scaffold(
      // The actual app bar is in the parent Scaffold (HomeScreen), 
      // but we add a title here for standalone testing clarity.
      // appBar: AppBar(
      //   title: Text("🌾 Wheat Disease Encyclopedia", style: theme.textTheme.titleLarge),
      //   backgroundColor: theme.scaffoldBackgroundColor, 
      //   elevation: 0,
      // ),
      body: ListView.builder(
        itemCount: wheatDiseases.length,
        itemBuilder: (context, index) {
          final d = wheatDiseases[index];
          
          return Card(
            // Use theme card styling
            color: theme.cardColor,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 8, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Increased radius
            child: Theme(
              data: theme.copyWith(
                // Ensure ExpansionTile uses theme icons/colors
                dividerColor: Colors.transparent,
                listTileTheme: ListTileThemeData(
                  iconColor: colorScheme.primary,
                  textColor: colorScheme.onSurface,
                ),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Increased padding
                collapsedIconColor: colorScheme.onSurface.withOpacity(0.7),
                iconColor: colorScheme.primary,
                
                // --- Leading Image/Icon ---
                leading: CircleAvatar(
                  radius: 30, // Larger avatar
                  backgroundColor: colorScheme.surfaceVariant,
                  // Use the primary image URL for the thumbnail
                  backgroundImage: (d["image"] != null)
                      ? NetworkImage(d["image"])
                      : null,
                  // Fallback icon if no image
                  child: (d["image"] == null)
                      ? Icon(Icons.agriculture_outlined, size: 30, color: colorScheme.primary)
                      : null,
                ),
                
                // --- Title ---
                title: Text(
                  d["name"] ?? 'Unknown Disease',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                
                // --- Subtitle (Severity & Onset) ---
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeverityBadge(context, d["severity"]),
                    if (d["onset"] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              d["onset"],
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
                
                // --- Expanded Content ---
                childrenPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                children: [
                  // Disease Image Gallery (Big Image First)
                  if (d["image"] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            d["image"],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.secondary));
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: colorScheme.surfaceVariant,
                              height: 180,
                              child: Center(child: Icon(Icons.broken_image, size: 48, color: colorScheme.onSurface.withOpacity(0.5))),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Small thumbnails row is removed for brevity and focus, 
                        // as the logic for full-screen view is outside the scope of this widget.
                      ],
                    ),

                  // Cause
                  InfoRow(
                    icon: Icons.science_outlined,
                    title: '🔬 What Causes It?',
                    content: d["cause"] ?? 'Information not available',
                  ),
                  const SizedBox(height: 16),

                  // Symptoms (bullet style for easy reading)
                  InfoRow(
                    icon: Icons.healing_outlined,
                    title: '🚨 Key Symptoms',
                    contentWidget: SymptomsWidget(symptoms: d["symptoms"]),
                  ),
                  const SizedBox(height: 16),

                  // Prevention (numbered steps)
                  InfoRow(
                    icon: Icons.shield_outlined,
                    title: '✅ How to Prevent It',
                    contentWidget: PreventionWidget(prevention: d["prevention"]),
                  ),
                  const SizedBox(height: 16),

                  // Treatment steps (if provided show steps)
                  if (d.containsKey("treatment"))
                    InfoRow(
                      icon: Icons.local_hospital_outlined,
                      title: '🩹 Immediate Treatment Steps',
                      contentWidget: TreatmentWidget(treatment: d["treatment"]),
                    ),
                  if (d.containsKey("treatment")) const SizedBox(height: 16),

                  // Recommended pesticide & dosage
                  if (d["recommended_pesticide"] != null)
                    InfoRow(
                      icon: Icons.medical_services_outlined,
                      title: '🛒 Recommended Product',
                      content:
                          '${d["recommended_pesticide"]}${d["dosage"] != null ? " — Dosage: ${d["dosage"]}" : ""}',
                    ),
                  const SizedBox(height: 20),

                  // Farmer feedback
                  _buildFarmerFeedbackSection(context, d["how_people_handled"]),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons row
                  _buildActionButtonsRow(context, d["name"]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS (Theme Compliant) ---

  Widget _buildSeverityBadge(BuildContext context, String? severity) {
    final theme = Theme.of(context);
    severity = severity?.toLowerCase() ?? 'moderate';
    Color color;
    Color bgColor;
    String label;

    switch (severity) {
      case 'high':
        color = theme.colorScheme.error;
        bgColor = theme.colorScheme.error.withOpacity(0.2);
        label = 'HIGH RISK';
        break;
      case 'low':
        color = theme.colorScheme.primary;
        bgColor = theme.colorScheme.primary.withOpacity(0.2);
        label = 'LOW RISK';
        break;
      case 'moderate':
      default:
        color = theme.colorScheme.secondary;
        bgColor = theme.colorScheme.secondary.withOpacity(0.2);
        label = 'MODERATE RISK';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8, top: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
  
  Widget _buildFarmerFeedbackSection(BuildContext context, dynamic feedbackList) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final List<String> feedback = (feedbackList is List) 
        ? feedbackList.map((e) => e.toString()).toList() 
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🧑‍🌾 Farmer Community Feedback', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        const SizedBox(height: 12),
        if (feedback.isNotEmpty)
          Column(
            children: feedback.map<Widget>((fb) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant, // Theme surface variant for subtle distinction
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(fb, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic))),
                  ],
                ),
              );
            }).toList(),
          )
        else
          Text(
            'No community feedback yet. Share your experience to help others!',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
          ),
      ],
    );
  }

  Widget _buildActionButtonsRow(BuildContext context, String diseaseName) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.check_circle_outline, color: colorScheme.onPrimary),
            label: Text('I TRIED THIS', style: TextStyle(color: colorScheme.onPrimary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary, // Primary action color
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 4,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as tried! Your feedback is valuable.')));
            },
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          icon: Icon(Icons.message_outlined, color: colorScheme.secondary),
          label: const Text('Feedback'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.secondary,
            side: BorderSide(color: colorScheme.secondary, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _showFeedbackDialog(context, diseaseName),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          backgroundColor: colorScheme.error, // Use error color for urgent action
          child: IconButton(
            icon: Icon(Icons.call, color: colorScheme.onError),
            tooltip: 'Call Local Agronomist',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📞 Connecting to expert... (Action placeholder)')));
            },
          ),
        )
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context, String diseaseName) {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Share Experience on $diseaseName', style: theme.textTheme.titleLarge),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(hintText: 'e.g., "Used fungicide, symptoms cleared in 5 days."', fillColor: theme.inputDecorationTheme.fillColor),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface))),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for sharing! Your feedback will help other farmers.')));
              }
            },
            child: const Text('Submit'),
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
          )
        ],
      ),
    );
  }
}

// -----------------------------
// Helper widgets (Updated to be theme-compliant)
// -----------------------------

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? content;
  final Widget? contentWidget;

  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    this.content,
    this.contentWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final Widget body = contentWidget ??
        Text(
          content ?? 'Not available',
          style: theme.textTheme.bodyMedium,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary), // Use Primary color for icons
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              body,
            ]),
          ),
        ],
      ),
    );
  }
}

class SymptomsWidget extends StatelessWidget {
  final dynamic symptoms;
  const SymptomsWidget({super.key, required this.symptoms});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final List<String> bullets = [];
    if (symptoms == null) {
      bullets.add('No information available');
    } else if (symptoms is List) {
      bullets.addAll((symptoms as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets.map((b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('• ', style: TextStyle(fontSize: 16, color: colorScheme.secondary)), // Use secondary color for bullets
          Expanded(child: Text(b, style: theme.textTheme.bodyMedium)),
        ]),
      )).toList(),
    );
  }
}

class PreventionWidget extends StatelessWidget {
  final dynamic prevention;
  const PreventionWidget({super.key, required this.prevention});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final List<String> steps = [];
    if (prevention == null) {
      steps.add('Not available');
    } else if (prevention is List) {
      steps.addAll((prevention as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((e) {
        final idx = e.key + 1;
        final text = e.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                // Use theme primary color for step number
                child: Text('$idx', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class TreatmentWidget extends StatelessWidget {
  final dynamic treatment;
  const TreatmentWidget({super.key, required this.treatment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<String> steps = [];
    if (treatment == null) {
      steps.add('No treatment info');
    } else if (treatment is List) {
      steps.addAll((treatment as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final txt = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Distinct styling for urgent steps (Treatment)
              CircleAvatar(radius: 12, backgroundColor: colorScheme.error.withOpacity(0.2), child: Text('$idx', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w600))),
              const SizedBox(width: 10),
              Expanded(child: Text(txt, style: theme.textTheme.bodyMedium)),
            ],
          ),
        );
      }).toList(),
    );
  }
}