use crate::compat::{compare, def, feature_compat, FeatureValue};

fn fv(key: &str, value: &str, importance: i64, classification: Option<&str>) -> FeatureValue {
    FeatureValue {
        key: key.to_string(),
        value: value.to_string(),
        importance,
        classification: classification.unwrap_or("preference").to_string(),
        visibility: "public".to_string(),
    }
}

#[test]
fn ordinal_compat_is_symmetric_and_peak_at_equal() {
    let d = def("communication.directness").unwrap();
    // options: prefers_indirect, mixed, direct, very_direct
    assert_eq!(feature_compat(d, "prefers_indirect", "prefers_indirect"), 1.0);
    assert_eq!(feature_compat(d, "prefers_indirect", "very_direct"), 0.0);
    assert_eq!(
        feature_compat(d, "mixed", "direct"),
        feature_compat(d, "direct", "mixed")
    );
    let mid = feature_compat(d, "mixed", "direct");
    assert!(mid > 0.0 && mid < 1.0);
}

#[test]
fn mismatch_high_importance_yields_alignment_flag() {
    let mine = vec![fv("communication.directness", "very_direct", 5, None)];
    let theirs = vec![fv("communication.directness", "prefers_indirect", 5, None)];
    let report = compare(&mine, &theirs, &[], &[]);
    let agg = &report.dimensions[0];
    assert_eq!(agg.compat, Some(0.0));
    assert_eq!(agg.alignment, "PotentialFriction");
    assert_eq!(agg.importance, 5);
    assert!(report.explain.iter().any(|e| e.level == "talk"));
}

#[test]
fn dealbreaker_extreme_conflict_is_detected() {
    let mine = vec![fv("planning.spontaneity", "prefer_planned", 5, Some("dealbreaker"))];
    let theirs = vec![fv("planning.spontaneity", "love_spontaneous", 5, None)];
    let report = compare(&mine, &theirs, &[], &[]);
    assert!(!report.dealbreaker_conflicts.is_empty());
}

#[test]
fn non_dealbreaker_mismatch_is_not_conflict() {
    let mine = vec![fv("planning.spontaneity", "prefer_planned", 5, None)];
    let theirs = vec![fv("planning.spontaneity", "love_spontaneous", 5, None)];
    let report = compare(&mine, &theirs, &[], &[]);
    assert!(report.dealbreaker_conflicts.is_empty());
}

#[test]
fn shared_interests_are_counted() {
    let mine = vec![fv("communication.directness", "direct", 3, None)];
    let theirs = vec![fv("communication.directness", "direct", 3, None)];
    let report = compare(
        &mine,
        &theirs,
        &["hiking".to_string(), "coffee".to_string()],
        &["hiking".to_string(), "chess".to_string()],
    );
    assert_eq!(report.shared_interests, vec!["hiking"]);
}

#[test]
fn missing_features_are_skipped_not_friction() {
    let mine = vec![fv("communication.directness", "direct", 3, None)];
    let theirs: Vec<FeatureValue> = vec![];
    let report = compare(&mine, &theirs, &[], &[]);
    assert!(report.dealbreaker_conflicts.is_empty());
    assert!(report
        .dimensions
        .iter()
        .all(|d| d.compat.is_none() || d.alignment == "Unknown"));
}

#[test]
fn catalog_has_expected_dimensions() {
    let catalog = crate::compat::catalog_json();
    let arr = catalog.as_array().unwrap();
    assert!(arr.iter().any(|d| d["dimension"] == "Communication"));
    assert!(arr.iter().any(|d| d["dimension"] == "Sensory"));
    let mut features_have_key = false;
    for group in arr {
        for f in group["features"].as_array().unwrap() {
            if f["key"] == "communication.directness" {
                features_have_key = true;
            }
        }
    }
    assert!(features_have_key);
}