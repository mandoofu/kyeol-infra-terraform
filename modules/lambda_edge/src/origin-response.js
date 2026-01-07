'use strict';

/**
 * Lambda@Edge - Origin Response Handler
 * 이미지 리사이징 처리
 * 
 * 사용법: {origin}/images/{width}x{height}/{quality}/{filename}
 * 예시: /images/300x200/80/product.jpg
 * 
 * 지원 형식: jpg, jpeg, png, webp, gif
 */

const querystring = require('querystring');

// 지원 확장자
const SUPPORTED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

// 기본값
const DEFAULT_QUALITY = 80;
const MAX_WIDTH = 2000;
const MAX_HEIGHT = 2000;

exports.handler = async (event, context, callback) => {
    const response = event.Records[0].cf.response;
    const request = event.Records[0].cf.request;

    // 2xx 응답이 아니면 그대로 반환 (S3에서 이미지를 찾지 못한 경우)
    if (response.status !== '200') {
        return callback(null, response);
    }

    // URI 파싱
    const uri = request.uri;

    // 이미지 리사이징 경로 확인 (/images/{width}x{height}/{quality}/{filename})
    const match = uri.match(/^\/images\/(\d+)x(\d+)(?:\/(\d+))?\/(.+)$/);

    if (!match) {
        // 리사이징 요청이 아니면 원본 반환
        return callback(null, response);
    }

    const width = Math.min(parseInt(match[1], 10), MAX_WIDTH);
    const height = Math.min(parseInt(match[2], 10), MAX_HEIGHT);
    const quality = match[3] ? Math.min(parseInt(match[3], 10), 100) : DEFAULT_QUALITY;
    const filename = match[4];

    // 확장자 확인
    const extension = filename.split('.').pop().toLowerCase();
    if (!SUPPORTED_EXTENSIONS.includes(extension)) {
        return callback(null, response);
    }

    try {
        // Sharp 라이브러리 로드 (Lambda Layer)
        const sharp = require('sharp');

        // 원본 이미지 가져오기 (Base64 → Buffer)
        const originalBody = Buffer.from(response.body, 'base64');

        // 출력 포맷 결정 (WebP 지원 시 WebP로 변환)
        const acceptHeader = request.headers['accept'] ? request.headers['accept'][0].value : '';
        const supportsWebP = acceptHeader.includes('image/webp');
        const outputFormat = supportsWebP ? 'webp' : extension === 'png' ? 'png' : 'jpeg';

        // 이미지 리사이징
        let resizedImage = sharp(originalBody)
            .resize(width, height, {
                fit: 'cover',
                position: 'center',
                withoutEnlargement: true
            });

        // 포맷별 옵션
        if (outputFormat === 'webp') {
            resizedImage = resizedImage.webp({ quality: quality });
        } else if (outputFormat === 'png') {
            resizedImage = resizedImage.png({ quality: quality });
        } else {
            resizedImage = resizedImage.jpeg({ quality: quality, progressive: true });
        }

        const buffer = await resizedImage.toBuffer();

        // 응답 수정
        response.body = buffer.toString('base64');
        response.bodyEncoding = 'base64';
        response.headers['content-type'] = [{
            key: 'Content-Type',
            value: `image/${outputFormat}`
        }];

        // 캐시 헤더 추가 (1년)
        response.headers['cache-control'] = [{
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable'
        }];

        // 리사이징 정보 헤더
        response.headers['x-image-resized'] = [{
            key: 'X-Image-Resized',
            value: `${width}x${height}q${quality}`
        }];

        return callback(null, response);

    } catch (error) {
        console.error('Image resize error:', error);
        // 에러 시 원본 반환
        return callback(null, response);
    }
};
