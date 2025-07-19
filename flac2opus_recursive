function flac2opus_recursive --description "Recursively convert FLAC to Opus @ 96kbps in parallel, preserving metadata and structure."
    # --- Check dependencies ---
    if not command -q ffmpeg; or not command -q ffprobe; or not command -q jq; or not command -q magick
        echo "Error: Missing dependencies." >&2
        echo "Please install ffmpeg, jq, and imagemagick." >&2
        return 1
    end

    # --- Argument parsing ---
    argparse --name=flac2opus_recursive h/help 'i/input=' 'o/output=' -- $argv
    or return 1

    # --- Show help message ---
    if set -q _flag_help
        echo "Usage: flac2opus_recursive -i <input_dir> -o <output_dir>"
        echo "Recursively finds *.flac files in <input_dir>, converts them to Opus 96kbps,"
        echo "and saves them directly to the destination using the structure:"
        echo "  <output_dir>/<Artist>/<Year> - <Album>/<Disc-Track> - <Title>.opus"
        return 0
    end

    # --- Validate arguments ---
    set -l input_dir "$_flag_input"
    set -l output_dir "$_flag_output"
    if test -z "$input_dir"; or test -z "$output_dir"
        echo "Error: Both input (-i) and output (-o) directories must be specified." >&2
        return 1
    end
    if not test -d "$input_dir"
        echo "Error: Input directory '$input_dir' not found." >&2
        return 1
    end
    mkdir -p "$output_dir"
    or return 1

    # --- Main Execution ---
    # Determine number of parallel jobs based on logical CPU cores
    set -l num_jobs (sysctl -n hw.logicalcpu 2>/dev/null)
    if test $status -ne 0; or not test "$num_jobs" -gt 0
        set num_jobs 4 # Fallback for systems without sysctl
    end
    echo "🚀 Starting conversion with up to $num_jobs parallel jobs..."

    # SOLUTION 1: Use a temporary script file with inline function
    set -l temp_script (mktemp)

    # Write the complete helper function to temp script using printf
    printf '#!/usr/bin/env fish

function process_single_flac
    set -l flac_file "$argv[1]"
    set -l output_dir "$argv[2]"
    
    # Extract metadata using ffprobe
    set -l metadata (ffprobe -v quiet -print_format json -show_format "$flac_file" | jq -r \'.format.tags // {}\')
    
    # Extract individual fields with fallbacks
    set -l artist (echo "$metadata" | jq -r \'.ALBUMARTIST // .AlbumArtist // .album_artist // .ARTIST // .Artist // .artist // "Unknown Artist"\')
    set -l album (echo "$metadata" | jq -r \'.ALBUM // .Album // .album // "Unknown Album"\')
    set -l title (echo "$metadata" | jq -r \'.TITLE // .Title // .title // "Unknown Title"\')
    set -l date (echo "$metadata" | jq -r \'.DATE // .Date // .date // "0000"\')
    set -l track_raw (echo "$metadata" | jq -r \'.TRACKNUMBER // .TrackNumber // .tracknumber // .TRACK // .Track // .track // "1"\')
    set -l disc_raw (echo "$metadata" | jq -r \'.DISCNUMBER // .DiscNumber // .discnumber // .DISC // .Disc // .disc // "1"\')
    
    # Clean track number (remove fraction if present like "1/12")
    set -l track (echo "$track_raw" | cut -d/ -f1)
    set -l disc (echo "$disc_raw" | cut -d/ -f1)
    
    # Ensure we have valid numbers, fallback to 1 if parsing fails
    if not string match -qr \'^\d+$\' "$track"
        set track 1
    end
    if not string match -qr \'^\d+$\' "$disc"
        set disc 1
    end
    
    # Format track/disc numbers with leading zeros
    if [ (string length -- "$track") -eq 1 ]
    set track "0$track"
end
if [ (string length -- "$disc") -eq 1 ]
    set disc "0$disc"
end
    
    # Create output directory structure
    set -l artist_dir (echo "$artist" | sed \'s/[\/]/_/g\')
    set -l album_dir (echo "$date - $album" | sed \'s/[\/]/_/g\')
    set -l output_path "$output_dir/$artist_dir/$album_dir"
    set -l output_album_dir "$output_path"
    
    mkdir -p "$output_path"
    
    # Generate output filename
    set -l filename (echo "$disc-$track - $title" | sed \'s/[\/]/_/g\')
    set -l output_file "$output_path/$filename.opus"
    set -l final_output_path "$output_file"
    
    # Skip if output file already exists
    if test -f "$output_file"
        echo "⏭️  Skipping (exists): $filename.opus"
        return 0
    end
    
    # Convert to Opus
    echo "🎵 Converting: $filename.opus"
    ffmpeg -i "$flac_file" -c:a libopus -b:a 96k -vbr on -compression_level 10 -frame_duration 60 -application audio -mapping_family 0 -y "$output_file" 2>/dev/null
    
    if test $status -eq 0
        echo "✅ Completed: $filename.opus"
    else
        echo "❌ Failed: $filename.opus"
        return 1
    end
    
    # Handle cover art extraction and processing
    set -l source_dir (dirname "$flac_file")
    set -l cover_art_output "$output_album_dir/cover.jpg"
    if not test -e "$cover_art_output"
        set -l found_art ""
        for art_name in "cover.jpg" "folder.jpg" "Cover.jpg" "Folder.jpg" "cover.png" "folder.png" "albumart.jpg" "front.jpg"
            set -l potential_art "$source_dir/$art_name"
            if test -e "$potential_art"
                set found_art "$potential_art"
                echo "🎨 Copying cover art \'$found_art\' -> \'$cover_art_output\'"
                cp "$found_art" "$cover_art_output"
                if test $status -ne 0
                    echo "⚠️  Warning: Failed to copy \'$found_art\' to \'$cover_art_output\'." >&2
                    set found_art ""
                else
                    # Downscale copied image
                    if test -f "$cover_art_output"
                        echo "🔄 Downscaling \'$cover_art_output\' to 480px width..."
                        magick "$cover_art_output" -resize 480 "$cover_art_output"
                        if test $status -ne 0
                            echo "⚠️  Warning: Failed to downscale \'$cover_art_output\'." >&2
                        end
                    end
                end
                break
            end
        end
        if test -z "$found_art"; and test -e "$final_output_path" # Check if opus file exists before trying extraction
            echo "🎨 Attempting to extract embedded cover art from \'$flac_file\' -> \'$cover_art_output\'"
            ffmpeg -n -v quiet -i "$flac_file" -an -c:v copy -map 0:v? -disposition:v attached_pic "$cover_art_output"
            if test $status -ne 0; or not test -s "$cover_art_output"
                if test -e "$cover_art_output"
                    rm -f "$cover_art_output"
                end
            else
                echo "✅ Successfully extracted embedded cover art."
                # Downscale extracted image
                if test -f "$cover_art_output"
                    echo "🔄 Downscaling \'$cover_art_output\' to 480px width..."
                    magick "$cover_art_output" -resize 480 "$cover_art_output"
                    if test $status -ne 0
                        echo "⚠️  Warning: Failed to downscale \'$cover_art_output\'." >&2
                    end
                end
            end
        end
    end
end

# Call the function with provided arguments
process_single_flac $argv[1] $argv[2]
' >"$temp_script"

    chmod +x "$temp_script"

    # Find all FLAC files and process them in parallel
    find "$input_dir" -type f -iname '*.flac' -print0 | xargs -0 -P "$num_jobs" -I {} "$temp_script" '{}' "$output_dir"

    # Clean up
    rm -f "$temp_script"

    echo "✅ Conversion process finished."
    return 0
end
