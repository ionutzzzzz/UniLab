% 71_bioinformatics_dna_alignment.m
% UniLab Complex Bioinformatics Pipeline: Global Sequence Alignment & Transcription
% This script aligns two homologous DNA sequences, computes their GC content, transcribes
% the sequences into RNA, and translates the transcribed RNA into amino acid sequences.

clear all;
close all;
clc;

disp('🧬 UniLab Homologous Sequence Alignment & Transcription Analysis');
disp('================================================================');

% homolog sequences representing two versions of a gene segment
seqA = 'ATGCGATACGTTTGCATAG';
seqB = 'ATGCGATACGTTCGCAT';

fprintf('Sequence A: %s (Length: %d)\n', seqA, length(seqA));
fprintf('Sequence B: %s (Length: %d)\n', seqB, length(seqB));

% Step 1: Global Sequence Alignment
disp('Performing Needleman-Wunsch global alignment...');
align_results = biomedical.dna_align(seqA, seqB, 2, -1, -2);

fprintf('  Alignment Score: %.1f\n', align_results.score);
fprintf('  Aligned Seq A:   %s\n', align_results.aligned_seq1);
fprintf('  Aligned Seq B:   %s\n', align_results.aligned_seq2);

% Step 2: Compute GC content
gcA = biomedical.dna_gc_content(seqA);
gcB = biomedical.dna_gc_content(seqB);
fprintf('  GC Content (Seq A): %.1f%%\n', gcA);
fprintf('  GC Content (Seq B): %.1f%%\n', gcB);

% Step 3: DNA transcription and translation to Protein
disp('Transcribing DNA sequences to RNA and translating to proteins...');
tx_results_A = biomedical.dna_transcription(seqA);
tx_results_B = biomedical.dna_transcription(seqB);

fprintf('  RNA Seq A:     %s\n', tx_results_A.rna_sequence);
fprintf('  Protein Seq A: %s\n', tx_results_A.protein_sequence);
fprintf('  RNA Seq B:     %s\n', tx_results_B.rna_sequence);
fprintf('  Protein Seq B: %s\n', tx_results_B.protein_sequence);

disp('Bioinformatics analysis completed successfully.');
