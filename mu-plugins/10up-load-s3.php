<?php
/**
 * Plugin Name:  10up - S3 Uploads compatibility
 * Description:  Load S3 Uploads vendor folder
 * Author:       10up, Felipe Elia
 * Author URI:   https://10up.com
 * License:      MIT
 *
 * @package TenUp
 */

namespace TenUp\LoadS3;

/**
 * Load S3 Uploads' vendor folder, so WP-CLI commands work.
 */
function load_s3_vendor_folder() {
	if ( ! defined( '\WP_CLI' ) || ! \WP_CLI ) {
		return;
	}

	$s3_folder = WP_PLUGIN_DIR . '/s3-uploads';

	if ( ! is_dir( $s3_folder ) ) {
		return;
	}

	if ( ! file_exists( $s3_folder . '/vendor/autoload.php' ) ) {
		return;
	}

	require_once $s3_folder . '/vendor/autoload.php';
}
add_action( 'muplugins_loaded', __NAMESPACE__ . '\load_s3_vendor_folder' );

/**
 * Use CF R2 instead of AWS S3.
 */
function set_cloudflare_endpoint( $params ) {
	$params['endpoint'] = 'https://43b858bd5a5da0cd1b0651745e770fff.r2.cloudflarestorage.com';
	$params['use_path_style_endpoint'] = true;
	$params['debug'] = false; // Set to true if uploads are failing.
	return $params;
}
add_filter( 's3_uploads_s3_client_params', __NAMESPACE__ . '\set_cloudflare_endpoint' );
